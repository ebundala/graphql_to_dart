import 'dart:async';
import 'dart:io';

import 'package:graphql_to_dart/src/builders/type_builder.dart';
import 'package:graphql_to_dart/src/constants/files.dart';
import 'package:graphql_to_dart/src/constants/type_converters.dart';
import 'package:graphql_to_dart/src/introspection_api_client/client.dart';
import 'package:graphql_to_dart/src/models/config.dart';
import 'package:graphql_to_dart/src/models/graphql_types.dart';
//import 'package:graphql_to_dart/src/parsers/config_parser.dart';

class GraphQlToDart {
  //final String yamlFilePath;
  final Config config;
  late GraphQLSchema schema;
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
      if (type.fields != null &&
          type.inputFields == null &&
          !type.name.startsWith("__") &&
          !ignoreFields.contains(type.name.toLowerCase())) {
        print("Creating model from: ${type.name}");
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
          !type.name.startsWith("__") &&
          type.inputFields == null) {
        print("Creating enum model from: ${type.name}");
        TypeBuilder builder = TypeBuilder(type, config);
        await builder.build();
        if (save) await builder.saveToFiles();
        outputs.addAll(builder.outputs);
      }
    });
    print("Formatting Generated Files");
    if (save) {
      await runFlutterFormat();
    }
    return outputs;
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
}
