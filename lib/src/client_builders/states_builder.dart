import 'package:graphql_to_dart/src/client_builders/bloc_builder.dart';
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
        case 'DatasetChanged':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> createOne() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'DatasetChanged':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> createMany() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'DatasetChanged':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> updateOne() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'DatasetChanged':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> updateMany() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'DatasetChanged':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> deleteOne() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'DatasetChanged':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> deleteMany() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'DatasetChanged':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> findUnique() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'DatasetChanged':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> findMany() {
    return states.map((e) {
      switch (e) {
        case 'Error':
          return classWithMessage(e);
        case 'Initial':
          return generic(e);
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'DatasetChanged':
        case 'MoreLoadedSuccess':
        case 'StreamEndedSuccess':
        case 'MoreLoadedFailure':
        case 'StreamEndedFailure':
        default:
          return classWithDataAndMessage(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
  }

  List<String> findFirst() {
    return states.map((e) {
      switch (e) {
        case 'Initial':
        case 'Success':
        case 'Failure':
        case 'InProgress':
        case 'DatasetChanged':
          return classWithDataAndMessage(e);
        case 'Error':
          return classWithMessage(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass())
      ..addAll(validationStates());
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
    final variables = getClassVariables(operation,r'$');
    final construct =
        "this.message, this.data,${buildConstructorArguments(operation,r"$")}";

    final name = '${ReCase(operation.operationName).pascalCase}${e}';
    final props = getPropsList(operation.variables).map((v)=>"\$$v").join(',');
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
