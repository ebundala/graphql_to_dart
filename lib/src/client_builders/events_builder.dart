import 'package:graphql_to_dart/src/client_builders/client_builder.dart';
import 'package:graphql_to_dart/src/client_builders/operation_ast.dart';
import 'package:recase/recase.dart';

class EventsBuilder {
  final OperationAstInfo operation;
  final List<String> events;
  String base;
  EventsBuilder({this.operation, this.events}) {
    base = "${operation.operationName.pascalCase}Event";
  }
  List<String> genericOperation() {
    return events.map((e) {
      switch (e) {
        case 'Excuted':
          return classWithVariables(e);
        case 'IsLoading':
        case 'IsOptimistic':
        case 'IsConcrete':
          return classWithData(e);
        case 'Refreshed':
          return classWithStateData(e);
        case 'Errored':
        case 'Failed':
          return classWithDataAndMessage(e);
        case 'Started':
        case 'Reseted':
        case 'Retried':
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }

  List<String> listOperation() {
    return events.map((e) {
      switch (e) {
        case 'Excuted':
        case 'MoreLoaded':
          return classWithVariables(e);
        case 'IsLoading':
        case 'IsOptimistic':
        case 'IsConcrete':
          return classWithData(e);
        case 'Refreshed':
          return classWithStateData(e);
        case 'Errored':
        case 'Failed':
          return classWithDataAndMessage(e);
        case 'Started':
        case 'Reseted':
        case 'Retried':
        case 'StreamEnded':
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
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

  String classWithData(e) {
    final name = "${ReCase(operation.operationName).pascalCase}${e}";
    return """
    class ${name} extends ${base}{
      final ${operation.returnType} data;
      ${name}({@required this.data});
       @override
     List<Object>  get props=>[data];
    }
    """;
  }

  String classWithVariables(e) {
    final variables = getClassVariables(operation);
    final construct = buildConstructorArguments(operation);
    final name = '${ReCase(operation.operationName).pascalCase}${e}';
    final props = getPropsList(operation.variables).join(',');
    return """
    class ${name} extends ${base}{
      ${variables.join('\n')}
      ${name}(${construct});
       @override
      List<Object> get props=>[${props}];
    }
    """;
  }

  String classWithStateData(String e) {
    final name = "${operation.operationName.pascalCase}${e}";
    return """
    class ${name} extends ${base}{
      final ${operation.operationName.pascalCase}State data;
      ${name}({@required this.data});
       @override
     List<Object>  get props=>[data];
    }
    """;
  }

  String classWithDataAndMessage(String e) {
    final name = "${operation.operationName.pascalCase}${e}";
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
}
