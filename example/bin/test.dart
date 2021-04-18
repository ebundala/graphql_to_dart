import 'dart:io';

import 'package:example/signup.op.ast.g.dart' as _;
import 'package:gql/ast.dart';
import 'package:graphql_to_dart/graphql_to_dart.dart';
import 'package:example/schema.ast.g.dart' show document;

main(List<String> args) async {
  var inputs = getInputsDef(document);
  var scalars = getScalarsAndEnums(document);
  var info = getOperationsInfo(document);
  var ops = getOperationInfoFromAst(
      document: _.document, scalars: scalars, info: info, inputs: inputs);
  var commonExt = buildCommonGraphQLClientHelpers();
  var filePath = fileName("lib/graphql/common/common_client", 'helpers');
  saveFile(filePath, commonExt);
  for (var i in ops) {
    print('generate op ${i.name} ${i.returnType}');

    //var bloc = buildBloc(i);
    var ext = buildGraphqlClientExtension(i);
    var events = buildEvents(i);
    var states = buildStates(i);
    var imports = (getModelsImports(i, 'package:example/graphql/models')
          ..insertAll(0, [
            "import 'package:equatable/equatable.dart';",
            "import 'package:meta/meta.dart';",
            "import 'package:graphql/client.dart';",
            "import  'package:example/graphql/common/common_client_helpers.dart';",
            "import 'package:example/${i.name}.op.ast.g.dart';"
          ]))
        .join('\n');

    var bloc = """
       ${imports}

       part "${i.name}_extensions.dart";
       part "${i.name}_events.dart";
       part "${i.name}_states.dart";

       class ${i.name}Bloc {}
     """;
    final stateFile = fileName("bin/${i.name}", 'states');
    final eventFile = fileName("bin/${i.name}", 'events');
    final extFile = fileName("bin/${i.name}", 'extensions');
    final blocFile = fileName("bin/${i.name}", 'bloc');
    List<List<String>> content = [];
    content.add([stateFile, "part of '${i.name}_bloc.dart';\n${states}"]);
    content.add([eventFile, "part of '${i.name}_bloc.dart';\n${events}"]);
    content.add([extFile, "part of '${i.name}_bloc.dart';\n${ext}"]);
    content.add([blocFile, bloc]);
    content.forEach((v) async {
      await saveFile(v[0], v[1]);
    });
    
    print(states);
  }
}

String fileName(String operationName, String name, [String ext = '.dart']) {
  return "/${operationName}_$name$ext";
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
