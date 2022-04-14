import 'dart:async';
import 'dart:io';

import 'package:graphql_to_dart/src/builders/type_builder.dart';
import 'package:graphql_to_dart/src/constants/files.dart';
import 'package:graphql_to_dart/src/constants/type_converters.dart';
import 'package:graphql_to_dart/src/introspection_api_client/client.dart';
import 'package:graphql_to_dart/src/models/config.dart';
import 'package:graphql_to_dart/src/models/graphql_types.dart';

class GraphQlToDart {
  final Config config;
  late GraphQLSchema schema;
  bool generated = false;
  Completer<bool> isGenerating = Completer();
  GraphQlToDart(this.config);
  static const List<String> ignoreFields = [
    "rootquerytype",
    "rootsubscriptiontype",
    "rootmutationtype",
    "mutation",
    "query",
    "subscription"
  ];

  Future<Map<String, String>> init({save: true}) async {
    generated = true;
    // config = conf;
    // if (config == null) {
    // config = await ConfigParser.parse(yamlFilePath);

    ValidationResult result = await config.validate();
    if (result.hasError) {
      throw Exception(result.errorMessage);
    }

    LocalGraphQLClient localGraphQLClient = LocalGraphQLClient();
    localGraphQLClient.init(config);

    schema = await localGraphQLClient.fetchTypes();

    TypeConverters converters = TypeConverters();
    converters.overrideTypes(config.typeOverride);
    final Map<String, String> outputs = {};
    await Future.forEach(schema.types, (Type type) async {
      var reserved = true;
      if (type.name != null) {
        reserved = type.name?.startsWith("__") == true;
      }
      if (type.fields != null &&
          type.inputFields == null &&
          type.name != null &&
          !reserved &&
          !ignoreFields.contains(type.name?.toLowerCase())) {
        print("Creating model from: ${type.name}");
        //TODO modify type to make objects fields nullable;
        type.fields = type.fields!.map<Field>((e) {
          if (e.type.kind == "NON_NULL") {
            e.type = e.type.ofType!;
          }
          return e;
        }).toList();
        TypeBuilder builder = TypeBuilder(type, config);
        await builder.build();
        if (save) await builder.saveToFiles();
        outputs.addAll(builder.outputs);
      }
      if (type.kind == 'INPUT_OBJECT' &&
          type.fields == null &&
          type.inputFields != null) {
        print("Creating input model from: ${type.name}");
        TypeBuilder builder = TypeBuilder(type, config);
        await builder.build();
        if (save) await builder.saveToFiles();
        outputs.addAll(builder.outputs);
      }
      if (type.kind == 'ENUM' &&
          type.fields == null &&
          !reserved &&
          type.inputFields == null) {
        print("Creating enum model from: ${type.name}");
        TypeBuilder builder = TypeBuilder(type, config);
        await builder.build();
        if (save) await builder.saveToFiles();
        outputs.addAll(builder.outputs);
      }
    });
    // print("Formatting Generated Files");
    if (save) {
      // await runFlutterFormat();
      var libEntry = [];
      outputs.forEach(((k, v) {
        libEntry.add('export "${k.split("/").last}";');
      }));
      libEntry.insertAll(0, ['library models;']);
      File lib =
          File(FileConstants().modelsDirectory!.path + "lib/models.dart");
      if (!(await lib.exists())) {
        await lib.create();
      }
      await lib.writeAsString(libEntry.join("\n"));
      File pubspec =
          File(FileConstants().modelsDirectory!.path + "pubspec.yaml");
      if (!(await pubspec.exists())) {
        await pubspec.create();
      }
      await pubspec.writeAsString(modelsPubSpec("1.0.1"));
    }
    generated = true;
    isGenerating.complete(generated);
    return outputs;
  }

  Future<bool> getStatus() {
    return isGenerating.future;
  }

  Future runFlutterFormat([String? path]) async {
    var dir;
    if (path != null) {
      dir = Directory.current.path + path;
    }
    Process.runSync(
      "flutter",
      ["format", dir ?? FileConstants().modelsDirectory!.path],
      runInShell: true,
    );
    print("Formatted Generated Files");
  }

  String modelsPubSpec([String version = "1.0.0"]) {
    return """
name: models
description: generated models.
version: ${version}
homepage: https://github.com/ebundala/graphql_to_dart
environment:
  sdk: ">=2.12.0 <3.0.0"
dependencies:
  flutter:
    sdk: flutter
  equatable: ^2.0.0
  gql: ^0.13.0-nullsafety.2
  http: any

#dev_dependencies:
    """;
  }
}
