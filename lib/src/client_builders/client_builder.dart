import 'package:gql/ast.dart';
import 'package:graphql_to_dart/src/client_builders/events_builder.dart';
import 'package:graphql_to_dart/src/client_builders/states_builder.dart';
import 'package:graphql_to_dart/src/client_builders/states_definitions.dart';
import "package:code_builder/code_builder.dart";
import 'package:graphql_to_dart/src/builders/from_node.dart';
import 'package:recase/recase.dart';
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
  if (ev.isEmpty) return {'generic': events['generic'] ?? <String>[]};
  return ev;
}

List<String> getPropsList(List<VariableInfo> variables) {
  return variables.map((v) {
    return v.name;
  }).toList();
}

String _getName(DefinitionNode def) {
  //if (def.name != null && def.name.value != null) return def.name.value;

  if (def is SchemaDefinitionNode) return "schema";

  if (def is OperationDefinitionNode) {
    if (def.type == OperationType.query) return "query";
    if (def.type == OperationType.mutation) return "mutation";
    if (def.type == OperationType.subscription) return "subscription";
  }
  if (def is DirectiveDefinitionNode) return def.name.value;
  if (def is TypeDefinitionNode) return def.name.value;
  if (def is FragmentDefinitionNode) return def.name.value;
  return "unknown";
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
    {required List<OperationInfo> info,
    required DocumentNode operationAst,
    required String package,
    required Map<String, InputObjectTypeDefinitionNode> inputs,
    required Map<String, ObjectTypeDefinitionNode> types,
    required String modelsPath,
    required String outDir,
    required List<String> scalars,
    required List<String> enums,
    required String helperPath}) {
  final operations = getOperationInfoFromAst(
      types: types,
      document: operationAst,
      scalars: scalars,
      enums: enums,
      info: info,
      inputs: inputs);
  List<List<String>> content = [];
  for (var i in operations) {
    final ext = buildGraphqlClientExtension(i);
    final events = buildEvents(i);
    final states = buildStates(i);
    final ast = getOperationCodeFromAstNode(operationAst);
    //${package}/${modelsPath}
    final imports = (getModelsImports(i, 'package:models')
          ..insertAll(0, [
            "import 'package:equatable/equatable.dart';",
            "import 'package:gql/ast.dart';",
            "import 'package:meta/meta.dart';",
            "import 'package:graphql/client.dart';",
            "import 'package:bloc/bloc.dart';",
            "import 'package:${package}/${helperPath}/common_client_helpers.dart';",
            "import '${i.name.snakeCase}_ast.dart' show document;"
          ]))
        .join('\n');
    final libname = i.operationName.pascalCase;
    final isList = i.isList
        ? """  
            else if (event is ${libname}MoreLoaded){      
              yield ${libname}LoadMoreInProgress(data:getData);
                ${i.name}LoadMore(event);
            }
             else if (event is ${libname}StreamEnded){
                yield ${libname}AllDataLoaded(data:getData);
            }
    """
        : "";
    final isListFn = i.isList
        ? """
    void ${i.name}LoadMore(${libname}MoreLoaded event) {
      client.${i.name}LoadMore(resultWrapper.observableQuery,${buildOperationParams(i.variables)});
    }
    """
        : "";
    final isloadingMoreEvent = i.isList
        ? """
       if(!(state is ${libname}LoadMoreInProgress))       
    """
        : "";
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
       ${libname}Bloc({@required this.client,this.hook}) : super(${libname}Initial(data:null));
        @override
        Stream<${libname}State> mapEventToState(${libname}Event event) async* {
          if (hook != null) {
            yield* hook(this, event, ${libname}BlocHookStage.before);
          }
         if (event is ${libname}Started) {
              yield ${libname}Initial(data:null);
            }
            if (event is ${libname}Excuted) {
              //start main excution 
              yield* ${i.name}(event);
            } else if (event is ${libname}IsLoading) {
              // emit loading state
              ${isloadingMoreEvent}
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
              yield ${libname}Error(data:state.data,message: event.message);
            }
            else if (event is ${libname}Retried){              
                ${i.name}Retry();
            }
            ${isList}
            

          if (hook != null) {
            yield* hook(this, event, ${libname}BlocHookStage.after);
          }
        }
        void ${i.name}Retry(){
          client.${i.name}Retry(resultWrapper.observableQuery);
        }
        ${isListFn}

        Stream<${libname}State> ${i.name}(${libname}Excuted event) async* {
          
          //validate all required fields of required args and emit relevant events
           ${buildInputsValidations(i)}
            {
            try {
              await closeResultWrapper();
              resultWrapper = await client.${i.name}(${buildOperationParams(i.variables)});
              //listen for changes 
              resultWrapper.subscription = resultWrapper.stream.listen((result) {
                //reset events before starting to emit new ones
                add(${libname}Reseted());
                Map<String, dynamic> errors = {};
                //collect errors/exceptions
                if (result.hasException) {
                  errors['status'] = false;
                  var message = 'Error';
                  if (result.exception.linkException != null) {
                    //link exception means complete failure possibly throw here
                    final exception = result.exception.linkException;
              if (exception is ServerException) {
                message = "Network error";
              } else if (exception is RequestFormatException) {
                message = "Request format error";
              } else if (exception is ResponseFormatException) {
                message = "Response format error";
              } else if (exception is ContextReadException) {
                message = "Context read error";
              } else if (exception is ContextWriteException) {
                message = "Context write error";
              }
                   
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
              //excute observable query;
              if(resultWrapper.isObservable){
              resultWrapper.observableQuery.fetchResults();
              }
            } catch (e) {
              //emit complete failure state;
              yield ${libname}Error(data:state.data,message: e.toString());
            }
          }
        }

        closeResultWrapper() async {
          if (resultWrapper != null) {
            if(resultWrapper.isObservable==true && resultWrapper.observableQuery!=null){
            await resultWrapper.observableQuery.close();
            }
            if(resultWrapper.isStream==true&&resultWrapper.stream!=null && resultWrapper.subscription!=null){
             await resultWrapper.subscription.cancel();
            }
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
  final validations = operation.variables
      .where((v) => v.isNonNull)
      .map((v) {
        return v.fields.where((f) => f.isNonNull).map((f) {
          var vf = "${v.name}?.${f.name}";
          var test = f.isList || f.type == 'String'
              ? "event.${vf}?.isEmpty==true"
              : "event.${vf}==null";
          var stateName =
              "${operation.operationName.pascalCase}${v.name.pascalCase}${f.name.pascalCase}";
          return """
      if(${test}){
        yield ${stateName}ValidationError('${f.name} is required',getData,${reAssignedInputs(operation.variables)});
      }
      """;
        }).join('\n else ');
      })
      .where((e) => e.isNotEmpty)
      .join('\n else ');
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
    var scalars = ['int', 'double', 'String', 'bool', 'DateTime'];

    if (!i.isScalar || scalars.where((e) => e == i.type).length == 0)
      v.add("import '${modelsPath}/${i.type.snakeCase}.dart';");
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
    if (v.isScalar) {
      return """
     if(${v.name} != null){
       vars.addAll({"${v.name}":${v.name}});
     }
      """;
    } else if (v.isEnum) {
      if (v.isList) {
        return """
     if(${v.name} != null){
       vars.addAll({"${v.name}":${v.name}.map((e)=>e.toJson()).toList()});
     }
      """;
      } else {
        return """
     if(${v.name} != null){
       vars.addAll({"${v.name}":${v.name}.toJson()});
     }
      """;
      }
    } else if (v.isList) {
      return """
         if(${v.name} != null){
        var i=-1;
      var files= ${v.name}.map((e){
         i++;
         return e.getFilesVariables(field_name: '${v.name}_\${i}');
       }).fold<Map<String, dynamic>>({}, (p, e){
        p.addAll(e);
        return p;
       });
        vars.addAll(files);
        args.add(ArgumentInfo(name: '${v.name}', value: ${v.name}));

       }
        """;
    } else {
      return """
    if(${v.name} != null){
    args.add(ArgumentInfo(name: '${v.name}', value: ${v.name}));
      vars.addAll(${v.name}.getFilesVariables(field_name: '${v.name}'));
     }
    """;
    }
  }).join('\n');

  fn.write("""
  final Map<String, dynamic> vars = {};
  final List<ArgumentInfo> args = [];
  ${variables}
  final doc = transform(document, [NormalizeArgumentsVisitor(args: args)]);
  final result = await runObservableOperation(this,document:doc,
  variables:vars,
  operationName:'${operation.operationName}');
  return result;
  """);
  fn.writeln("}");
  fn.write("""
  //refetch fn
    void ${operation.name}Retry(ObservableQuery observableQuery) {
      if (observableQuery.isRefetchSafe)
        observableQuery.refetch();
    }
  """);
  if (operation.isList) {
    fn.write("""
   //load more fn
    void ${operation.name}LoadMore(ObservableQuery observableQuery,${buildFnArguments(operation.variables)})  {
      final Map<String, dynamic> vars = {};
      final List<ArgumentInfo> args = [];
      ${variables}
      final doc = transform(document, [NormalizeArgumentsVisitor(args: args)]);
      observableQuery.fetchMore(
        FetchMoreOptions(
         document:doc,
         variables:vars,
          updateQuery: (p, n) {
            if (n != null) {
            var data = n['${operation.operationName}'];
            if (p != null) {
              var data2 = p['${operation.operationName}'];
              if (data2 != null && data != null) {
                if (data2['data'] is List && data['data'] is List) {
                  (data2['data'] as List).addAll((data['data'] as List));
                  p['data'] = data2;
                  return p;
                }
              }
            } else {
              return n;
            }
          }

          return p;
          },
        
        ),
      );
    }
  """);
  }
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
  return """
import 'package:gql/ast.dart';
import 'package:graphql/client.dart';
import 'dart:async';

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
  StreamSubscription<QueryResult> subscription;

   OperationResult(
      {this.isStream = false,
      this.observableQuery,
      this.result,
      this.stream,
      this.subscription,
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

Future<OperationResult> runObservableOperation(
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
  String operationName
}) async {
  var info = getOperationInfo(document);

  var result;
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
      result = await client.subscribe(SubscriptionOptions(
        document: document,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
        cacheRereadPolicy: cacheRereadPolicy,
        context: context,
        optimisticResult: optimisticResult,
      ),);
      break;
  }

  if(result is ObservableQuery){
     var stream = result.stream.map((res) {
      var data = getDataFromField(operationName, res);
      res.data = data;
      return res;
    });
    return OperationResult(
        isObservable: true, observableQuery: result, stream: stream);
  }
  else if(result is Stream<QueryResult>){
     var stream = result.map((res) {
        var data = getDataFromField(operationName, res);
      res.data = data;
      return res;
      });
      return OperationResult(isStream: true, stream: stream,);
  }else{
        throw UnsupportedError("Operation is not supported");
  }
}

Map<String, dynamic> getDataFromField(fieldName, QueryResult result) {
  // if (!result.hasException&&) {
  if (result.data != null) return result.data['\${fieldName}'];
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

${buildArgumentsNormalizer()}
  """;
}

String buildArgumentsNormalizer() {
  return r"""
  class ArgumentInfo {
  final String name;
  final dynamic value;
  ArgumentInfo({this.name, this.value});
}

class NormalizeArgumentsVisitor extends TransformingVisitor {
  final List<ArgumentInfo> args;
  List<VariableDefinitionNode> definitions = [];
  Map<String, ValueNode> valueNodes = {};

  NormalizeArgumentsVisitor({this.args}) : super() {
    args.forEach((v) {
      final value = v.value;
      Map<String, dynamic> vars;
      if (value is List) {
        var i = -1;
        vars = value.map((e) {
          i++;
          return e.getFilesVariables(field_name: '${v.name}_${i}');
        }).fold<Map<String, dynamic>>({}, (p, e) {
          p.addAll(e);
          return p;
        });
        valueNodes[v.name] = ListValueNode(
          values: value
              .map<ValueNode>(
                (e) => e?.toValueNode(field_name: v.name),
              )
              .toList(),
        );
        definitions.addAll(
          value
              .map<List<VariableDefinitionNode>>(
                  (e) => e?.getVariableDefinitionsNodes(variables: vars) ?? [])
              .fold<List<VariableDefinitionNode>>(
            [],
            (p, n) {
              p.addAll(n);
              return p;
            },
          ).toList(),
        );
      } else {
        vars = value?.getFilesVariables(field_name: v.name);
        valueNodes[v.name] = value?.toValueNode(field_name: v.name);
        definitions
            .addAll(value?.getVariableDefinitionsNodes(variables: vars) ?? []);
      }
    });

   
  }
  // @override
  // FieldNode visitFieldNode(FieldNode node) {
  //   final normalized = argsNodes.where((e) {
  //     if(e.value is )
  //     valueNodes[e.value.name.value] != null;
  //   }).toList();
  //   final newNode = FieldNode(
  //     name: node.name,
  //     alias: node.alias,
  //     arguments: [
  //       ...node.arguments
  //           .where((e) => e.value
  //               is! VariableNode /* valueNodes[e.value.name.value] == null */)
  //           .toList(),
  //     ],
  //     directives: node.directives,
  //     selectionSet: node.selectionSet,
  //   );
  //   return newNode;
  // }

  @override
  OperationDefinitionNode visitOperationDefinitionNode(
      OperationDefinitionNode node) {
  

    return OperationDefinitionNode(
        directives: node.directives,
        name: node.name,
        selectionSet: node.selectionSet,
        type: node.type,
        variableDefinitions: [
          ...node.variableDefinitions.where((element) {
            return args.firstWhere((e) => e.name == element.variable.name.value,
                    orElse: () => null) ==
                null;
          }).toList(),
          ...definitions
        ]);
  }

  

  @override
  ArgumentNode visitArgumentNode(ArgumentNode node) {
    //add arguments values
    if (node.value is VariableNode) {
      final v = node.value as VariableNode;
      final newArgValue = valueNodes[v.name.value];
      if (newArgValue != null)
        return ArgumentNode(name: node.name, value: newArgValue);
    }
    return node;
  }
}
  """;
}
