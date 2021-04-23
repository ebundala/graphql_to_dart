import 'package:graphql_to_dart/src/client_builders/client_builder.dart';
import 'package:graphql_to_dart/src/client_builders/operation_ast.dart';
import 'package:recase/recase.dart';

class StatesBuilder {
  final OperationAstInfo operation;
  final List<String> states;
  String base;
  StatesBuilder({this.operation, this.states}) {
    base = "${ReCase(operation.operationName).pascalCase}State";
  }

  List<String> genericOperation() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'Optimistic':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> listOperation() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'Optimistic':
        case 'LoadMoreInProgress':
        case 'AllDataLoaded':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> createOne() {
    return genericOperation();
  }

  List<String> createMany() {
    return listOperation();
  }

  List<String> updateOne() {
    return genericOperation();
  }

  List<String> updateMany() {
    return listOperation();
  }

  List<String> deleteOne() {
    return genericOperation();
  }

  List<String> deleteMany() {
    return listOperation();
  }

  List<String> findUnique() {
    return genericOperation();
  }

  List<String> findMany() {
    return listOperation();
  }

  List<String> findFirst() {
    return genericOperation();
  }

  String generic(String e) {
    return """
    class ${ReCase(operation.operationName).pascalCase}${e} extends ${base}{
      @override
      List<Object>  get props=>[];
    }
    """;
  }

  String baseClass() {
    return """
    abstract class ${base} extends Equatable{
       @override
      List<Object> get props=>[];
    }
    """;
  }

  String classWithMessage(String e) {
    final name = "${ReCase(operation.operationName).pascalCase}${e}";
    return """
    class ${name} extends ${base}{
      final String message;
      ${name}({@required this.message});
       @override
     List<Object>  get  props=>[message];
    }
    """;
  }

  String classWithDataAndMessage(e) {
    final name = "${ReCase(operation.operationName).pascalCase}${e}";
    return """
    class ${name} extends ${base}{
      final ${operation.returnType} data;
      final String message;
      ${name}({@required this.data,this.message});
       @override
     List<Object>  get props=>[data,message];
    }
    """;
  }

  List<String> validationStates() {
    return operation.variables.map((a) {
      return a.fields.where((f) => f.isNonNull).map((v) {
        return classWithVariablesMessageAndData(
            "${a.name.pascalCase}${v.name.pascalCase}ValidationError");
      });
    }).fold<List<String>>([], (p, v) {
      p.addAll(v);
      return p;
    });
  }

  String classWithVariablesMessageAndData(e) {
    final variables = getClassVariables(operation, r'$');
    final construct =
        "this.message, this.data,${buildConstructorArguments(operation, r"$")}";

    final name = '${ReCase(operation.operationName).pascalCase}${e}';
    final props =
        getPropsList(operation.variables).map((v) => "\$$v").join(',');
    return """
    class ${name} extends ${base}{
      ${variables.join('\n')}
      final ${operation.returnType} data;
      final String message;
      ${name}(${construct});
       @override
      List<Object> get props=>[${props},message,data];
    }
    """;
  }
}
