import 'package:graphql_to_dart/src/client_builders/events_builder.dart';
import 'package:graphql_to_dart/src/client_builders/states_builder.dart';
import 'package:graphql_to_dart/src/client_builders/states_definitions.dart';

import '../../graphql_to_dart.dart';
import './events_definitions.dart';

String buildEvents(OperationAstInfo operation) {
  var eventMap = getEventsMapping(operation, events);
  var _name;
  var _events;
  if (eventMap.isNotEmpty) {
    eventMap.forEach((k, v) {
      _name = k;
      _events = v;
    });
    List<String> eventString = [];
    var eventBuilder = EventsBuilder(operation: operation, events: _events);
    switch (_name) {
      case 'createOne':
        eventString = eventBuilder.createOne();
        break;
      case 'createMany':
        eventString = eventBuilder.createOne();
        break;
      case 'updateOne':
        eventString = eventBuilder.updateOne();
        break;
      case 'updateMany':
        eventString = eventBuilder.updateMany();
        break;
      case 'deleteOne':
        eventString = eventBuilder.deleteOne();
        break;
      case 'deleteMany':
        eventString = eventBuilder.deleteMany();
        break;
      case 'findUnique':
        eventString = eventBuilder.findUnique();
        break;
      case 'findMany':
        eventString = eventBuilder.findMany();
        break;
      case 'findFirst':
        eventString = eventBuilder.findFirst();
        break;
      default:
        eventString = eventBuilder.genericOperation();
        break;
    }
    return eventString.join('\n');
  }
  return '';
}

String buildStates(OperationAstInfo operation) {
  var statesMap = getEventsMapping(operation, states);
  var _name;
  var _states;
  if (statesMap.isNotEmpty) {
    statesMap.forEach((k, v) {
      _name = k;
      _states = v;
    });
    List<String> statesString = [];
    var statesBuilder = StatesBuilder(operation: operation, states: _states);
    switch (_name) {
      case 'createOne':
        statesString = statesBuilder.createOne();
        break;
      case 'createMany':
        statesString = statesBuilder.createOne();
        break;
      case 'updateOne':
        statesString = statesBuilder.updateOne();
        break;
      case 'updateMany':
        statesString = statesBuilder.updateMany();
        break;
      case 'deleteOne':
        statesString = statesBuilder.deleteOne();
        break;
      case 'deleteMany':
        statesString = statesBuilder.deleteMany();
        break;
      case 'findUnique':
        statesString = statesBuilder.findUnique();
        break;
      case 'findMany':
        statesString = statesBuilder.findMany();
        break;
      case 'findFirst':
        statesString = statesBuilder.findFirst();
        break;
      default:
        statesString = statesBuilder.genericOperation();
        break;
    }
    return statesString.join('\n');
  }
  return '';
}

Map<String, List<String>> getEventsMapping(
    OperationAstInfo operation, Map<String, List<String>> events) {
  var operationName = operation.operationName;
  Map<String, List<String>> ev = {};
  events.forEach((k, v) {
    if (operationName.contains(k)) {
      ev.addAll({k: v});
    }
  });
  if (ev.isEmpty) return {'generic': events['generic']};
  return ev;
}

List<String> getPropsList(List<VariableInfo> variables) {
  return variables.map((v) {
    return v.name;
  }).toList();
}

List<String> getClassVariables(OperationAstInfo operation,
    [String prefix = '', bool makeFinal = true]) {
  return operation.variables.map((v) {
    var isFinal = "${makeFinal ? 'final' : ''}";
    var isList = "${v.isList ? 'List<${v.type}>' : v.type}";
    return "${isFinal} ${isList} ${prefix}${v.name};";
  }).toList();
}

String buildConstructorArguments(
  OperationAstInfo operation, [
  prefix = '',
  useThis = true,
]) {
  var vr = StringBuffer();
  var joinedVars = operation.variables.map((v) {
    var isNonNull = "${v.isNonNull ? '@required' : ''}";
    return "${isNonNull} ${useThis ? 'this.' : ''}${prefix}${v.name}";
  }).join(',');
  vr.write(joinedVars);
  return wrapWith('{', vr, '}').toString();
}

String buildBloc(OperationAstInfo operation) {}

List<String> getVariablesImports(
    OperationAstInfo operation, String modelsPath) {
  return operation.variables.fold<List<String>>([], (v, i) {
    if (!i.isScalar) v.add("import '${modelsPath}/${i.type}.dart';");
    return v;
  });
}

String buildGraphqlClientExtension(OperationAstInfo operation) {
  var fn = StringBuffer();

  fn.writeln('extension on GraphQLClient {');
  fn.writeln(
      "Future<OperationResult> ${operation.name}(${buildFnArguments(operation.variables)}) async {");
  var variables = operation.variables.map((v) {
    return """if(${v.name} != null){
      vars["${v.name}"]=${v.isScalar ? '${v.name}' : '${v.isList ? "${v.name}.map((v)=>v.toJson())" : '${v.name}.toJson()'};'}
    }""";
  }).join('\n');
  fn.write("""
  final vars={};
  ${variables}
  final result = await runObservableOperation(document:document,variables:vars);
  var stream = result.stream.map((res) {
      return ${operation.returnType}.fromJson(res);
    });
    return OperationResult(
        isObservable: true, result.observableQuery: result, stream: stream);
  """);
  fn.writeln("}");
  fn.writeln('}');
  return fn.toString();
}

String buildFnArguments(List<VariableInfo> variables) {
  var vr = StringBuffer();
  var joinedVars = variables.map((v) {
    var isNonNull = "${v.isNonNull ? '@required' : ''}";
    var isList = "${v.isList ? 'List<${v.type}>' : v.type}";
    return "${isNonNull} ${isList} ${v.name}";
  }).join(',');
  vr.write(joinedVars);
  return wrapWith('{', vr, '}').toString();
}

StringBuffer wrapWith(String begin, StringBuffer content, String end) {
  final wrapped = StringBuffer(begin);
  wrapped.write(content);
  wrapped.write(end);
  return wrapped;
}

String buildCommonGraphQLClientExtensions() {
  return r"""
import 'package:gql/ast.dart';
import 'package:graphql/client.dart';

class OperationRuntimeInfo {
  final String operationName;
  final String fieldName;
  final OperationType type;
  const OperationRuntimeInfo({this.operationName, this.fieldName, this.type});
}

class OperationResult {
  final bool isStream;
  final bool isObservable;
  final Map<String, dynamic> result;
  final Stream<Map<String, dynamic>> stream;
  final ObservableQuery observableQuery;

  const OperationResult(
      {this.isStream = false,
      this.observableQuery,
      this.result,
      this.stream,
      this.isObservable = false});
}

extension on GraphQLClient {
  Future<OperationResult> runOperation(
      {DocumentNode document,
      Map<String, dynamic> variables,
      FetchPolicy fetchPolicy,
      ErrorPolicy errorPolicy,
      CacheRereadPolicy cacheRereadPolicy,
      Context context,
      Object optimisticResult,
      void Function(dynamic) onCompleted,
      void Function(GraphQLDataProxy, QueryResult) update,
      void Function(OperationException) onError}) async {
    var info = getOperationInfo(document);

    var result;
    switch (info.type) {
      case OperationType.query:
        result = await query(QueryOptions(
          document: document,
          variables: variables,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          context: context,
          optimisticResult: optimisticResult,
        ));
        break;
      case OperationType.mutation:
        result = await mutate(MutationOptions(
            document: document,
            variables: variables,
            fetchPolicy: fetchPolicy,
            errorPolicy: errorPolicy,
            cacheRereadPolicy: cacheRereadPolicy,
            context: context,
            optimisticResult: optimisticResult,
            onCompleted: onCompleted,
            update: update,
            onError: onError));
        break;
      case OperationType.subscription:
        var subscription = await subscribe(SubscriptionOptions(
          document: document,
          variables: variables,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          context: context,
          optimisticResult: optimisticResult,
        ));
        var data = subscription.map((result) {
          return getDataFromField(info.fieldName, result);
        });
        return OperationResult(isStream: true, stream: data);
        break;
    }
    var data = getDataFromField(info.fieldName, result);
    return OperationResult(result: data);
  }

  Future<ObservableQuery> runObservableOperation({
    DocumentNode document,
    Map<String, dynamic> variables,
    FetchPolicy fetchPolicy,
    ErrorPolicy errorPolicy,
    CacheRereadPolicy cacheRereadPolicy,
    Context context,
    Object optimisticResult,
    Duration pollInterval,
    bool fetchResults = false,
    bool carryForwardDataOnException = true,
    bool eagerlyFetchResults,
  }) async {
    var info = getOperationInfo(document);

    ObservableQuery result;
    switch (info.type) {
      case OperationType.query:
        result = watchQuery(WatchQueryOptions(
            document: document,
            variables: variables,
            fetchPolicy: fetchPolicy,
            errorPolicy: errorPolicy,
            cacheRereadPolicy: cacheRereadPolicy,
            context: context,
            optimisticResult: optimisticResult,
            fetchResults: fetchResults,
            eagerlyFetchResults: eagerlyFetchResults,
            pollInterval: pollInterval,
            carryForwardDataOnException: carryForwardDataOnException));
        break;
      case OperationType.mutation:
        result = await watchMutation(WatchQueryOptions(
            document: document,
            variables: variables,
            fetchPolicy: fetchPolicy,
            errorPolicy: errorPolicy,
            cacheRereadPolicy: cacheRereadPolicy,
            context: context,
            optimisticResult: optimisticResult,
            fetchResults: fetchResults,
            eagerlyFetchResults: eagerlyFetchResults,
            pollInterval: pollInterval,
            carryForwardDataOnException: carryForwardDataOnException));
        break;
      case OperationType.subscription:
      default:
        // var subscription = await subscribe(SubscriptionOptions(
        //   document: document,
        //   variables: variables,
        //   fetchPolicy: fetchPolicy,
        //   errorPolicy: errorPolicy,
        //   cacheRereadPolicy: cacheRereadPolicy,
        //   context: context,
        //   optimisticResult: optimisticResult,

        // ));
        // var data = subscription.map((result) {
        //   return getDataFromField(info.fieldName, result);
        // });
        // return OperationResult(isStream: true, stream: data);
        throw UnsupportedError(
            "Subscription observable query is not supported");
        break;
    }
   
    return result;
  }

  Map<String, dynamic> getDataFromField(fieldName, QueryResult result) {
    if (!result.hasException) {
      if (result.data != null) return result.data['${fieldName}'];
      return null;
    } else {
      //handle errors here
      throw OperationException(
          linkException: result.exception.linkException,
          graphqlErrors: result.exception.graphqlErrors);
    }
  }

  OperationRuntimeInfo getOperationInfo(DocumentNode document) {
    var defs = document.definitions;
    if (defs?.isNotEmpty == true) {
      var predicate = (DefinitionNode v) {
        if (v is OperationDefinitionNode) {
          if (v.selectionSet != null) {
            return true;
          }
        }
        return false;
      };
      OperationDefinitionNode op = defs.firstWhere(predicate);
      var type = op.type;
      var name = op?.name?.value;
      FieldNode field = op.selectionSet?.selections?.firstWhere((v) {
        if (v is FieldNode) {
          if (v.selectionSet != null) {
            return true;
          }
        }
        return false;
      });
      var fieldName = field?.name?.value;
      return OperationRuntimeInfo(
          fieldName: fieldName, operationName: name, type: type);
    }
    return null;
  }
}
  """;
}
