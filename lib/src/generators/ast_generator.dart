import "dart:async";
import 'package:graphql/client.dart';
import "package:path/path.dart" as p;
import "package:glob/glob.dart";

import "package:build/build.dart";
import "package:code_builder/code_builder.dart";
import "package:dart_style/dart_style.dart";
import "package:gql/ast.dart";
//import "package:gql/language.dart";
import "package:gql_code_gen/gql_code_gen.dart";
import "package:pedantic/pedantic.dart";

const graphqlExtension = ".graphql";
const astExtension = ".ast.g.dart";

Set<String> allRelativeImports(String doc) {
  final imports = <String>{};
  for (final pattern in [
    RegExp(r'^#\s*import\s+"([^"]+)"', multiLine: true),
    RegExp(r"^#\s*import\s+'([^']+)'", multiLine: true)
  ]) {
    pattern.allMatches(doc)?.forEach((m) {
      final path = m?.group(1);
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

    final imports = allRelativeImports(importMap[id.path])
        .map((i) => p.normalize(p.joinAll([...segments, i])))
        .where((i) => !importMap.containsKey(i)) // avoid duplicates/cycles
        .toSet();

    seenImports.addAll(imports);

    final assetIds = await Stream.fromIterable(imports)
        .asyncExpand(
          (relativeImport) => buildStep.findAssets(Glob(relativeImport)),
        )
        .toSet();

    for (final assetId in assetIds) {
      await collectContentRecursivelyFrom(assetId);
    }
  }

  await collectContentRecursivelyFrom(buildStep.inputId);

  seenImports
      .where(
        (i) => !importMap.containsKey(i),
      )
      .forEach(
        (missing) => log.warning("Could not import missing file $missing."),
      );

  return importMap.values.join("\n\n\n");
}

String _getName(DefinitionNode def) {
  if (def.name != null && def.name.value != null) return def.name.value;

  if (def is SchemaDefinitionNode) return "schema";

  if (def is OperationDefinitionNode) {
    if (def.type == OperationType.query) return "query";
    if (def.type == OperationType.mutation) return "mutation";
    if (def.type == OperationType.subscription) return "subscription";
  }

  return null;
}

class AstGenerator implements Builder {
  final DartFormatter _dartfmt = DartFormatter();

  @override
  Map<String, List<String>> get buildExtensions => {
        graphqlExtension: [astExtension],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final allContent = await inlineImportsRecursively(buildStep);
    // final doc = parseString(
    //   allContent,
    //   url: buildStep.inputId.path,
    // );
    final doc = gql(allContent);
    
    final definitions = doc.definitions.map(
      (def) => fromNode(def).assignConst(_getName(def)).statement,
    );

    final document = refer(
      "DocumentNode",
      "package:gql/ast.dart",
    )
        .call(
          [],
          {
            "definitions": literalList(
              doc.definitions.map(
                (def) => refer(
                  _getName(def),
                ),
              ),
            ),
          },
        )
        .assignConst("document")
        .statement;

    final library = Library(
      (b) => b.body
        ..addAll(definitions)
        ..add(document),
    );

    final genSrc = _dartfmt.format("${library.accept(
      DartEmitter.scoped(),
    )}");

    unawaited(
      buildStep.writeAsString(
        buildStep.inputId.changeExtension(astExtension),
        genSrc,
      ),
    );
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
