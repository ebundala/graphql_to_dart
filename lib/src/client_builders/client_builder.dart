import 'package:gql/ast.dart';
import 'package:gql_code_gen/gql_code_gen.dart';
import 'package:graphql_to_dart/src/client_builders/events_builder.dart';
import 'package:graphql_to_dart/src/client_builders/states_builder.dart';
import 'package:graphql_to_dart/src/client_builders/states_definitions.dart';
import "package:code_builder/code_builder.dart";
import "package:dart_style/dart_style.dart";

import 'package:recase/recase.dart';
import 'package:meta/meta.dart';
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

String getOperationCodeFromAstNode(DocumentNode doc) {
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

  return "${library.accept(
    DartEmitter.scoped(),
  )}";
}

List<String> getClassVariables(OperationAstInfo operation,
    [String prefix = '', bool makeFinal = true]) {
  if (operation.variables.isEmpty) return [];
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
  if (operation.variables.isEmpty) {
    return '';
  }
  var vr = StringBuffer();
  var joinedVars = operation.variables.map((v) {
    var isNonNull = "${v.isNonNull ? '@required' : ''}";
    return "${isNonNull} ${useThis ? 'this.' : ''}${prefix}${v.name}";
  }).join(',');
  vr.write(joinedVars);
  return wrapWith('{', vr, '}').toString();
}

List<List<String>> buildBloc(
    {@required List<OperationInfo> info,
    @required DocumentNode operationAst,
    @required String package,
    @required Map<String, InputObjectTypeDefinitionNode> inputs,
    @required String modelsPath,
    @required String outDir,
    @required List<String> scalars,
    @required String helperPath}) {
  var operations = getOperationInfoFromAst(
      document: operationAst, scalars: scalars, info: info, inputs: inputs);
  List<List<String>> content = [];
  for (var i in operations) {
    final ext = buildGraphqlClientExtension(i);
    final events = buildEvents(i);
    final states = buildStates(i);
    final ast = getOperationCodeFromAstNode(operationAst);
    final imports = (getModelsImports(i, 'package:${package}/${modelsPath}')
          ..insertAll(0, [
            "import 'package:equatable/equatable.dart';",
            "import 'package:meta/meta.dart';",
            "import 'package:graphql/client.dart';",
            "import 'package:bloc/bloc.dart';",
            "import 'package:${package}/${helperPath}/common_client_helpers.dart';",
            "import '${i.name.snakeCase}_ast.dart' show document;"
          ]))
        .join('\n');
    final libname = i.operationName.pascalCase;
    var bloc = """
       ${imports}

       part "${i.name.snakeCase}_extensions.dart";
       part "${i.name.snakeCase}_events.dart";
       part "${i.name.snakeCase}_states.dart";

       enum ${libname}BlocHookStage { before, after }

      class ${libname}Bloc extends Bloc<${libname}Event, ${libname}State> {
           final GraphQLClient client;
          final Stream<${libname}State> Function(
      ${libname}Bloc context, ${libname}Event event, ${libname}BlocHookStage stage) hook;
      OperationResult resultWrapper;
       ${libname}Bloc({@required this.client,this.hook}) : super(${libname}Initial());
        @override
        Stream<${libname}State> mapEventToState(${libname}Event event) async* {
          if (hook != null) {
            yield* hook(this, event, ${libname}BlocHookStage.before);
          }
         if (event is ${libname}Started) {
              yield ${libname}Initial();
            }
            if (event is ${libname}Excuted) {
              //start main excution 
              yield* ${i.name}(event);
            } else if (event is ${libname}IsLoading) {
              // emit loading state
              yield ${libname}InProgress(data: event.data);
            } else if (event is ${libname}IsOptimistic) {
              // emit optimistic result state
              yield ${libname}Optimistic(data: event.data);
            } else if (event is ${libname}IsConcrete) {
              // emit completed result
              yield ${libname}Success(data: event.data);
            } else if (event is ${libname}Refreshed) {
              //emit dataset changed
              yield event.data;
            } else if (event is ${libname}Failed) {
              // emit failure state
              yield ${libname}Failure(data: event.data, message: event.message);
            } else if (event is ${libname}Errored) {
              //emit error case
              yield ${libname}Error(message: event.message);
            }

          if (hook != null) {
            yield* hook(this, event, ${libname}BlocHookStage.after);
          }
        }

      
        Stream<${libname}State> ${i.name}(${libname}Excuted event) async* {
          
          //validate all required fields of required args and emit relevant events
           ${buildInputsValidations(i)}
            {
            try {
              await closeResultWrapper();
              resultWrapper = await client.${i.name}(${buildOperationParams(i.variables)});
              //listen for changes 
              resultWrapper.stream.listen((result) {
                //reset events before starting to emit new ones
                add(${libname}Reseted());
                Map<String, dynamic> errors = {};
                //collect errors/exceptions
                if (result.hasException) {
                  errors['status'] = false;
                  var message = 'Error';
                  if (result.exception.linkException != null) {
                    //link exception means complete failure possibly throw here
                    message =
                        result.exception.linkException.originalException?.message;
                  } else if (result.exception.graphqlErrors?.isNotEmpty == true) {
                    // failure but migth have data available
                    message = result.exception.graphqlErrors.map((e) {
                      return e.message;
                    }).join('\\n');
                  }
                  errors['message'] = message;
                }
                // convert result to data type expected by listeners
                ${i.returnType} data;
                if (result.data != null) {
                  //add errors encountered to result
                  result.data.addAll(errors);
                  data = ${i.returnType}.fromJson(result.data);
                } else if (errors.isNotEmpty) {
                // errors['data'] = null;
                  data = ${i.returnType}.fromJson(errors);
                }
                if (result.hasException) {
                  if (result.exception.linkException != null) {
                    //emit error event
                    add(${libname}Errored(data: data, message: data.message));
                  } else if (result.exception.graphqlErrors?.isNotEmpty == true) {
                    //emit failure event
                    add(${libname}Failed(data: data, message: data.message));
                  }
                } else if (result.isLoading) {
                  //emit loading event
                  add(${libname}IsLoading(data: data));
                } else if (result.isOptimistic) {
                  //emit optimistic event
                  add(${libname}IsOptimistic(data: data));
                } else if (result.isConcrete) {
                  //emit completed event
                  add(${libname}IsConcrete(data: data));
                }
              });
              resultWrapper.observableQuery.fetchResults();
            } catch (e) {
              //emit complete failure state;
              yield ${libname}Error(message: e.toString());
            }
          }
        }

        closeResultWrapper() async {
          if (resultWrapper != null) {
            await resultWrapper.observableQuery.close();
          }
        }
       ${i.returnType} get getData{
          return (state is ${i.operationName.pascalCase}Initial)||(state is ${i.operationName.pascalCase}Error)?null:(state as dynamic)?.data;

        }
        @override
        Future<void> close() async {
          await closeResultWrapper();
          return super.close();
        }

      }
     """;
    final stateFile = fileName("${outDir}/${i.name.snakeCase}", 'states');
    final eventFile = fileName("${outDir}/${i.name.snakeCase}", 'events');
    final extFile = fileName("${outDir}/${i.name.snakeCase}", 'extensions');
    final blocFile = fileName("${outDir}/${i.name.snakeCase}", 'bloc');
    final astFile = fileName("${outDir}/${i.name.snakeCase}", "ast");
    content.add([astFile, ast]);
    content.add(
        [stateFile, "part of '${i.name.snakeCase}_bloc.dart';\n${states}"]);
    content.add(
        [eventFile, "part of '${i.name.snakeCase}_bloc.dart';\n${events}"]);
    content.add([extFile, "part of '${i.name.snakeCase}_bloc.dart';\n${ext}"]);
    content.add([blocFile, bloc]);
  }
  return content;
}

buildOperationParams(List<VariableInfo> variables) {
  if (variables.isNotEmpty) {
    var joinedVars = variables.map((v) {
      return "${v.name}:event.${v.name}";
    }).join(',');
    return joinedVars;
  }
  return '';
}

buildInputsValidations(OperationAstInfo operation) {
  final validations = operation.variables.where((v) => v.isNonNull).map((v) {
    return v.fields.where((f) => f.isNonNull).map((f) {
      var vf = "${v.name}?.${f.name}";
      var test = f.isList ? "event.${vf}?.isEmpty==true" : "event.${vf}==null";
      var stateName =
          "${operation.operationName.pascalCase}${v.name.pascalCase}${f.name.pascalCase}";
      return """
      if(${test}){
        yield ${stateName}ValidationError('${f.name} is required',getData,${reAssignedInputs(operation.variables)});
      }
      """;
    }).join('\n else ');
  }).join('\n else ');
  if (validations.isNotEmpty) return "${validations} \nelse ";
  return '';
}

String reAssignedInputs(List<VariableInfo> variables) {
  return variables.map((v) {
    return "\$${v.name}:event.${v.name}";
  }).join(',');
}

String fileName(String operationName, String name, [String ext = '.dart']) {
  return "/${operationName}_$name$ext";
}

List<String> getModelsImports(OperationAstInfo operation, String modelsPath) {
  return operation.variables.fold<List<String>>([], (v, i) {
    if (!i.isScalar) v.add("import '${modelsPath}/${i.type.snakeCase}.dart';");
    return v;
  })
    ..add("import '${modelsPath}/${operation.returnType.snakeCase}.dart';");
}

String buildGraphqlClientExtension(OperationAstInfo operation) {
  var fn = StringBuffer();

  fn.writeln('extension on GraphQLClient {');
  fn.writeln(
      "Future<OperationResult> ${operation.name}(${buildFnArguments(operation.variables)}) async {");
  var variables = operation.variables.map((v) {
    return """if(${v.name} != null){
      vars["${v.name}"]=${v.isScalar ? '${v.name};' : '${v.isList ? "${v.name}.map((v)=>v.toJson())" : '${v.name}.toJson()'};'}
    }""";
  }).join('\n');
  fn.write("""
  final Map<String, dynamic> vars = {};
  ${variables}
  final result = await runObservableOperation(this,document:document,variables:vars);
     var stream = result.stream.map((res) {
      var data = getDataFromField('${operation.operationName}', res);
      res.data = data;
      return res;
    });
    return OperationResult(
        isObservable: true, observableQuery: result, stream: stream);
  """);
  fn.writeln("}");
  fn.writeln('}');
  return fn.toString();
}

String buildFnArguments(List<VariableInfo> variables) {
  if (variables.isNotEmpty) {
    var vr = StringBuffer();
    var joinedVars = variables.map((v) {
      var isNonNull = "${v.isNonNull ? '@required' : ''}";
      var isList = "${v.isList ? 'List<${v.type}>' : v.type}";
      return "${isNonNull} ${isList} ${v.name}";
    }).join(',');
    vr.write(joinedVars);
    return wrapWith('{', vr, '}').toString();
  }
  return '';
}

StringBuffer wrapWith(String begin, StringBuffer content, String end) {
  final wrapped = StringBuffer(begin);
  wrapped.write(content);
  wrapped.write(end);
  return wrapped;
}

String buildCommonGraphQLClientHelpers() {
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
  """;
}
