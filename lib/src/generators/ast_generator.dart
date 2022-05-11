import "dart:async";
import 'dart:io';
import 'package:graphql/client.dart';
import 'package:graphql_to_dart/src/client_builders/client_builder.dart';
import 'package:graphql_to_dart/src/introspection_api_client/introspection_schema.dart';
import 'package:graphql_to_dart/src/models/config.dart';
//import 'package:graphql_to_dart/src/models/graphql_types.dart';
import "package:path/path.dart" as p;
import "package:glob/glob.dart";

import "package:build/build.dart";
import "package:gql/ast.dart";
//import "package:gql/language.dart";
import '../../graphql_to_dart.dart';

const graphqlExtension = ".graphql";
const astExtension = ".ast.g.dart";

Set<String> allRelativeImports(String doc) {
  final imports = <String>{};
  for (final pattern in [
    RegExp(r'^#\s*import\s+"([^"]+)"', multiLine: true),
    RegExp(r"^#\s*import\s+'([^']+)'", multiLine: true)
  ]) {
    pattern.allMatches(doc).forEach((m) {
      final path = m.group(1);
      if (path != null) {
        imports.add(
          path.endsWith(graphqlExtension) ? path : "$path$graphqlExtension",
        );
      }
    });
  }

  return imports;
}

Future<String> inlineImportsRecursively(BuildStep buildStep) async {
  final Map<String, String> importMap = {};
  final Set<String> seenImports = {};

  void collectContentRecursivelyFrom(AssetId id) async {
    importMap[id.path] = await buildStep.readAsString(id);
    final segments = id.pathSegments..removeLast();
    var i = importMap[id.path];
    late var imports;
    if (i != null) {
      imports = allRelativeImports(i)
          .map((i) => p.normalize(p.joinAll([...segments, i])))
          .where((i) => !importMap.containsKey(i)) // avoid duplicates/cycles
          .toSet();

      seenImports.addAll(imports);
    }

    final assetIds = await Stream.fromIterable(imports)
        .asyncExpand(
          (relativeImport) => buildStep.findAssets(Glob(relativeImport)),
        )
        .toSet();

    for (final assetId in assetIds) {
      collectContentRecursivelyFrom(assetId);
    }
  }

  collectContentRecursivelyFrom(buildStep.inputId);

  seenImports
      .where(
        (i) => !importMap.containsKey(i),
      )
      .forEach(
        (missing) => log.warning("Could not import missing file $missing."),
      );

  return importMap.values.join("\n\n\n");
}

//bool generated = false;

class AstGenerator implements Builder {
  //final DartFormatter _dartfmt = DartFormatter();
  late Map<String, InputObjectTypeDefinitionNode> inputs;
  late Map<String, ObjectTypeDefinitionNode> types;

  late Map<String, ScalarTypeDefinitionNode> scalars;
  late Map<String, EnumTypeDefinitionNode> enums;
  late List<OperationInfo> info;
  //DocumentNode? schema;
  late GraphQlToDart graphQlToDart;
  final BuilderOptions options;
  late IntrospectionSchema _schema;
  late Config config;

  AstGenerator(this.options) {
    config = Config.fromJson(options.config);
    // final file = File(config.schemaPath);

    final helperStr = buildCommonGraphQLClientHelpers();
    final customTypesMixinStr = buildGraphqlCustomTypesBaseClass();
    final helperFile = "/lib/${config.helperPath}/${config.helperFilename}";
    final customTypeMixinFile =
        "/${config.modelsDirectoryPath}lib/${config.graphqlCustomTypeMixinFilename}";
    saveFile(helperFile, helperStr);
    saveFile(customTypeMixinFile, customTypesMixinStr);
    graphQlToDart = GraphQlToDart(config);
    graphQlToDart.init();
    // if (file.existsSync()) {
    //   var schemaStr = file.readAsStringSync();
    //   schema = gql(schemaStr);
    //   _schema = IntrospectionSchema.fromDocumentNode(schema);
    //   // inputs = getInputsDef(schema);
    //   // scalars = getScalarsAndEnums(schema);
    //   // info = getOperationsInfo(schema);
    //   // types = getTypesMapping(schema);
    // } else {
    //   throw Exception("Schema not found");
    // }
  }
  saveFile(
    String fileName,
    String content,
  ) async {
    Directory current = Directory.current;
    File file = File(current.path + fileName);
    if (!(await file.exists())) {
      await file.create();
    }
    await file.writeAsString(content);
    return null;
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        graphqlExtension: [astExtension],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    if (await graphQlToDart.getStatus()) {
      // graphQlToDart.init();
      _schema = IntrospectionSchema.fromTypes(graphQlToDart.schema.types);
      info = _schema.operationInfo();

      scalars = _schema.scalarsMap();
      enums = _schema.enumsMap();

      inputs = _schema.inputsMap();
      types = _schema.objectsMap();
    }
    //final package = buildStep.inputId.package;
    final outDIR =
        p.normalize(p.joinAll(buildStep.inputId.pathSegments..removeLast()));
    final str = await buildStep.readAsString(buildStep.inputId);
    var operationAst = gql(str);

    var content = buildBloc(
        info: info,
        types: types,
        scalars: scalars,
        enums: enums,
        inputs: inputs,
        operationAst: operationAst,
        outDir: outDIR,
        config: config
        // package: package,
        // modelsPath: config.modelsImportPath,
        // modelsPackage: config.modelsPackage,
        // helperPath: config.helperPath,
        // customScalarsPaths: config.customScalarImplementationPaths,
        );
    content.forEach((v) async {
      await saveFile(v[0], v[1]);
    });

    // await graphQlToDart.runFlutterFormat(outDIR);
    // final allContent = await inlineImportsRecursively(buildStep);
    // // final doc = parseString(
    // //   allContent,
    // //   url: buildStep.inputId.path,
    // // );
    // final doc = gql(allContent);

    // final definitions = doc.definitions.map(
    //   (def) => fromNode(def).assignConst(_getName(def)).statement,
    // );

    // final document = refer(
    //   "DocumentNode",
    //   "package:gql/ast.dart",
    // )
    //     .call(
    //       [],
    //       {
    //         "definitions": literalList(
    //           doc.definitions.map(
    //             (def) => refer(
    //               _getName(def),
    //             ),
    //           ),
    //         ),
    //       },
    //     )
    //     .assignConst("document")
    //     .statement;

    // final library = Library(
    //   (b) => b.body
    //     ..addAll(definitions)
    //     ..add(document),
    // );

    // final genSrc = _dartfmt.format("${library.accept(
    //   DartEmitter.scoped(),
    // )}");

    // unawaited(
    //   buildStep.writeAsString(
    //     buildStep.inputId.changeExtension(astExtension),
    //     genSrc,
    //   ),
    // );
  }
}


 

// import 'package:build/build.dart';
// import 'package:graphql/client.dart';
// import 'package:source_gen/source_gen.dart';
// //import "package:gql/language.dart" as lang;
// import "package:gql_code_gen/gql_code_gen.dart" as dart;
// import "package:code_builder/code_builder.dart";
// //import "package:dart_style/dart_style.dart";

// class AstGenerator extends Generator {
//   @override
//   Future<String> generate(LibraryReader lib, BuildStep step) async {
//     var text = await step.readAsString(step.inputId);
//     var query = gql(text);
//     final Expression docExpression = dart.fromNode(
//       query,
//     );
//     final library = Library(
//       (b) => b.body.add(
//         docExpression.assignFinal("document").statement,
//       ),
//     );
//     // final formatted = DartFormatter().format(
//     //   "${library.accept(
//     //     DartEmitter.scoped(),
//     //   )}",
//     // );
//     // }
//     return "${library.accept(DartEmitter.scoped())}";
//   }
// }
