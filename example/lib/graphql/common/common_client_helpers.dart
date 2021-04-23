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
  final Stream<QueryResult> stream;
  final ObservableQuery observableQuery;

  const OperationResult(
      {this.isStream = false,
      this.observableQuery,
      this.result,
      this.stream,
      this.isObservable = false});
}

Future<OperationResult> runOperation(GraphQLClient client,
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
      result = await client.query(QueryOptions(
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
      result = await client.mutate(MutationOptions(
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
      var subscription = await client.subscribe(SubscriptionOptions(
        document: document,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
        cacheRereadPolicy: cacheRereadPolicy,
        context: context,
        optimisticResult: optimisticResult,
      ));
      var data = subscription.map((result) {
        var res = getDataFromField(info.fieldName, result);
        if (res != null) {
          result.data = res;
        }
        return result;
      });
      return OperationResult(isStream: true, stream: data);
      break;
  }
  var data = getDataFromField(info.fieldName, result);
  return OperationResult(result: data);
}

Future<ObservableQuery> runObservableOperation(
  GraphQLClient client, {
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
      result = client.watchQuery(WatchQueryOptions(
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
      result = await client.watchMutation(WatchQueryOptions(
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
      throw UnsupportedError("Subscription observable query is not supported");
      break;
  }

  return result;
}

Map<String, dynamic> getDataFromField(fieldName, QueryResult result) {
  // if (!result.hasException&&) {
  if (result.data != null) return result.data['${fieldName}'];
  return null;
  // } else {
  //   //handle errors here
  //   throw OperationException(
  //       linkException: result.exception.linkException,
  //       graphqlErrors: result.exception.graphqlErrors);
  // }
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
