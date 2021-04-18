import 'package:graphql_to_dart/src/client_builders/bloc_builder.dart';
import 'package:graphql_to_dart/src/client_builders/operation_ast.dart';
import 'package:recase/recase.dart';

class EventsBuilder {
  final OperationAstInfo operation;
  final List<String> events;
  String base;
  EventsBuilder({this.operation, this.events}) {
    
    base = "${ReCase(operation.operationName).pascalCase}Event";
  }
  List<String> genericOperation() {
    return events.map((e) {
      switch (e) {
        case 'Started':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }
  List<String> createOne() {
    return events.map((e) {
      switch (e) {
        case 'Started':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }

  List<String> createMany() {
    return events.map((e) {
      switch (e) {
        case 'initial':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }

  List<String> updateOne() {
    return events.map((e) {
      switch (e) {
        case 'initial':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }

  List<String> updateMany() {
    return events.map((e) {
      switch (e) {
        case 'initial':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }

  List<String> deleteOne() {
    return events.map((e) {
      switch (e) {
        case 'initial':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }

  List<String> deleteMany() {
    return events.map((e) {
      switch (e) {
        case 'initial':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }

  List<String> findUnique() {
    return events.map((e) {
      switch (e) {
        case 'initial':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }

  List<String> findMany() {
    return events.map((e) {
      switch (e) {
        case 'initial':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        case 'MoreLoaded':
          return generic(e);
        case 'StreamEnded':
          return generic(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
  }

  List<String> findFirst() {
    return events.map((e) {
      switch (e) {
        case 'initial':
          return generic(e);
        case 'Excuted':
          return classWithVariables(e);
        case 'Aborted':
          return generic(e);
        case 'Retried':
          return classWithVariables(e);
        case 'Reseted':
          return generic(e);
        case 'Refreshed':
          return classWithData(e);
        case 'Errored':
          return classWithMessage(e);
        case 'MoreLoaded':
          return generic(e);
        case 'StreamEnded':
          return generic(e);
        default:
          return generic(e);
      }
    }).toList()
      ..insert(0, baseClass());
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
}
