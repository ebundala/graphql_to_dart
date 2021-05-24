//import "package:gql/ast.dart" as ast;
//import "package:gql/language.dart" as lang;
//import "package:gql_code_gen/gql_code_gen.dart" as dart;
//import 'package:graphql_to_dart/graphql_to_dart.dart';
//import '../lib/graphql/models/service_category_list_response.dart';
//import "package:code_builder/code_builder.dart";
//import "package:dart_style/dart_style.dart";

void main(List<String> arguments) async {
//   final HttpLink _httpLink = HttpLink(
//     "http://localhost:3000/graphql",
//   );
//   final AuthLink _authLink = AuthLink(getToken: () async => 'xxxxx CONSUMER');
//   var client = GraphQLClient(
//     cache: GraphQLCache(store: InMemoryStore()),
//     link: _authLink.concat(_httpLink),
//   );

//   var query = gql("""
//  query getCategories{
//    findManyServiceCategory{
//      status
//      message
//      data{
//        id
//        name
//        createdAt
//        updatedAt
//      }
//    }
//  }
//  """);

  // var result = await client.runObservableOperation(document: query);
  // var sub = result.stream.listen((v) async {
  //   if (v != null) {
  //     var data = ServiceCategoryListResponse.fromJson(v);
  //     if (data.status) {
  //       data.data.forEach((c) {
  //         print(c.toJson());
  //       });
  //     }
  //   }
  // });

  // result.observableQuery.fetchResults();
  // await sub.asFuture();
}

// class OperationRuntimeInfo {
//   final String operationName;
//   final String fieldName;
//   final OperationType type;
//   const OperationRuntimeInfo({this.operationName, this.fieldName, this.type});
// }

// class OperationResult {
//   final bool isStream;
//   final bool isObservable;
//   final Map<String, dynamic> result;
//   final Stream<Map<String, dynamic>> stream;
//   final ObservableQuery observableQuery;

//   const OperationResult(
//       {this.isStream = false,
//       this.observableQuery,
//       this.result,
//       this.stream,
//       this.isObservable = false});
// }

// extension on GraphQLClient {
//   Future<OperationResult> runOperation(
//       {DocumentNode document,
//       Map<String, dynamic> variables,
//       FetchPolicy fetchPolicy,
//       ErrorPolicy errorPolicy,
//       CacheRereadPolicy cacheRereadPolicy,
//       Context context,
//       Object optimisticResult,
//       void Function(dynamic) onCompleted,
//       void Function(GraphQLDataProxy, QueryResult) update,
//       void Function(OperationException) onError}) async {
//     var info = getOperationInfo(document);

//     var result;
//     switch (info.type) {
//       case OperationType.query:
//         result = await query(QueryOptions(
//           document: document,
//           variables: variables,
//           fetchPolicy: fetchPolicy,
//           errorPolicy: errorPolicy,
//           cacheRereadPolicy: cacheRereadPolicy,
//           context: context,
//           optimisticResult: optimisticResult,
//         ));
//         break;
//       case OperationType.mutation:
//         result = await mutate(MutationOptions(
//             document: document,
//             variables: variables,
//             fetchPolicy: fetchPolicy,
//             errorPolicy: errorPolicy,
//             cacheRereadPolicy: cacheRereadPolicy,
//             context: context,
//             optimisticResult: optimisticResult,
//             onCompleted: onCompleted,
//             update: update,
//             onError: onError));
//         break;
//       case OperationType.subscription:
//         var subscription = await subscribe(SubscriptionOptions(
//           document: document,
//           variables: variables,
//           fetchPolicy: fetchPolicy,
//           errorPolicy: errorPolicy,
//           cacheRereadPolicy: cacheRereadPolicy,
//           context: context,
//           optimisticResult: optimisticResult,
//         ));
//         var data = subscription.map((result) {
//           return getDataFromField(info.fieldName, result);
//         });
//         return OperationResult(isStream: true, stream: data);
//         break;
//     }
//     var data = getDataFromField(info.fieldName, result);
//     return OperationResult(result: data);
//   }

//   Future<ObservableQuery> runObservableOperation({
//     DocumentNode document,
//     Map<String, dynamic> variables,
//     FetchPolicy fetchPolicy,
//     ErrorPolicy errorPolicy,
//     CacheRereadPolicy cacheRereadPolicy,
//     Context context,
//     Object optimisticResult,
//     Duration pollInterval,
//     bool fetchResults = false,
//     bool carryForwardDataOnException = true,
//     bool eagerlyFetchResults,
//   }) async {
//     var info = getOperationInfo(document);

//     ObservableQuery result;
//     switch (info.type) {
//       case OperationType.query:
//         result = watchQuery(WatchQueryOptions(
//             document: document,
//             variables: variables,
//             fetchPolicy: fetchPolicy,
//             errorPolicy: errorPolicy,
//             cacheRereadPolicy: cacheRereadPolicy,
//             context: context,
//             optimisticResult: optimisticResult,
//             fetchResults: fetchResults,
//             eagerlyFetchResults: eagerlyFetchResults,
//             pollInterval: pollInterval,
//             carryForwardDataOnException: carryForwardDataOnException));
//         break;
//       case OperationType.mutation:
//         result = await watchMutation(WatchQueryOptions(
//             document: document,
//             variables: variables,
//             fetchPolicy: fetchPolicy,
//             errorPolicy: errorPolicy,
//             cacheRereadPolicy: cacheRereadPolicy,
//             context: context,
//             optimisticResult: optimisticResult,
//             fetchResults: fetchResults,
//             eagerlyFetchResults: eagerlyFetchResults,
//             pollInterval: pollInterval,
//             carryForwardDataOnException: carryForwardDataOnException));
//         break;
//       case OperationType.subscription:
//       default:
//         // var subscription = await subscribe(SubscriptionOptions(
//         //   document: document,
//         //   variables: variables,
//         //   fetchPolicy: fetchPolicy,
//         //   errorPolicy: errorPolicy,
//         //   cacheRereadPolicy: cacheRereadPolicy,
//         //   context: context,
//         //   optimisticResult: optimisticResult,

//         // ));
//         // var data = subscription.map((result) {
//         //   return getDataFromField(info.fieldName, result);
//         // });
//         // return OperationResult(isStream: true, stream: data);
//         throw UnsupportedError(
//             "Subscription observable query is not supported");
//         break;
//     }

//     return result;
//   }

//   Map<String, dynamic> getDataFromField(fieldName, QueryResult result) {
//     if (!result.hasException) {
//       if (result.data != null) return result.data['${fieldName}'];
//       return null;
//     } else {
//       //handle errors here
//       throw OperationException(
//           linkException: result.exception.linkException,
//           graphqlErrors: result.exception.graphqlErrors);
//     }
//   }

//   OperationRuntimeInfo getOperationInfo(DocumentNode document) {
//     var defs = document.definitions;
//     if (defs?.isNotEmpty == true) {
//       var predicate = (DefinitionNode v) {
//         if (v is OperationDefinitionNode) {
//           if (v.selectionSet != null) {
//             return true;
//           }
//         }
//         return false;
//       };
//       OperationDefinitionNode op = defs.firstWhere(predicate);
//       var type = op.type;
//       var name = op?.name?.value;
//       FieldNode field = op.selectionSet?.selections?.firstWhere((v) {
//         if (v is FieldNode) {
//           if (v.selectionSet != null) {
//             return true;
//           }
//         }
//         return false;
//       });
//       var fieldName = field?.name?.value;
//       return OperationRuntimeInfo(
//           fieldName: fieldName, operationName: name, type: type);
//     }
//     return null;
//   }
// }

// // void codeGen() {
// //   GraphQlToDart graphQlToDart = GraphQlToDart("graphql_config.yaml");
// //   graphQlToDart.init();
// // }

// // String buildOperationsAst(String operation) {
// //   var query = gql(operation);

// //   final Expression docExpression = dart.fromNode(
// //     query,
// //   );

// //   final library = Library(
// //     (b) => b.body.add(
// //       docExpression.assignFinal("document").statement,
// //     ),
// //   );

// //   final formatted = DartFormatter().format(
// //     "${library.accept(
// //       DartEmitter.scoped(),
// //     )}",
// //   );

// //   return formatted;
// // }
