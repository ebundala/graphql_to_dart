       import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:meta/meta.dart';
import 'package:graphql/client.dart';
import 'package:bloc/bloc.dart';
import 'package:example/graphql/common/common_client_helpers.dart';
import 'signup_ast.dart' show document;
import 'package:example/graphql/models/signup_input.dart';
import 'package:example/graphql/models/organization_create_without_owner_input.dart';
import 'package:example/graphql/models/auth_result.dart';

       part "signup_extensions.dart";
       part "signup_events.dart";
       part "signup_states.dart";

       enum SignupBlocHookStage { before, after }

      class SignupBloc extends Bloc<SignupEvent, SignupState> {
           final GraphQLClient client;
          final Stream<SignupState> Function(
      SignupBloc context, SignupEvent event, SignupBlocHookStage stage) hook;
      OperationResult resultWrapper;
       SignupBloc({@required this.client,this.hook}) : super(SignupInitial(data:null));
        @override
        Stream<SignupState> mapEventToState(SignupEvent event) async* {
          if (hook != null) {
            yield* hook(this, event, SignupBlocHookStage.before);
          }
         if (event is SignupStarted) {
              yield SignupInitial(data:null);
            }
            if (event is SignupExcuted) {
              //start main excution 
              yield* signup(event);
            } else if (event is SignupIsLoading) {
              // emit loading state
              
              yield SignupInProgress(data: event.data);
            } else if (event is SignupIsOptimistic) {
              // emit optimistic result state
              yield SignupOptimistic(data: event.data);
            } else if (event is SignupIsConcrete) {
              // emit completed result
              yield SignupSuccess(data: event.data);
            } else if (event is SignupRefreshed) {
              //emit dataset changed
              yield event.data;
            } else if (event is SignupFailed) {
              // emit failure state
              yield SignupFailure(data: event.data, message: event.message);
            } else if (event is SignupErrored) {
              //emit error case
              yield SignupError(data:state.data,message: event.message);
            }
            else if (event is SignupRetried){              
                signupRetry();
            }
            
            

          if (hook != null) {
            yield* hook(this, event, SignupBlocHookStage.after);
          }
        }
        void signupRetry(){
          client.signupRetry(resultWrapper.observableQuery);
        }
        

        Stream<SignupState> signup(SignupExcuted event) async* {
          
          //validate all required fields of required args and emit relevant events
                 if(event.credentials?.email?.isEmpty==true){
        yield SignupCredentialsEmailValidationError('email is required',getData,$credentials:event.credentials,$organization:event.organization);
      }
      
 else       if(event.credentials?.password?.isEmpty==true){
        yield SignupCredentialsPasswordValidationError('password is required',getData,$credentials:event.credentials,$organization:event.organization);
      }
      
 else       if(event.credentials?.displayName?.isEmpty==true){
        yield SignupCredentialsDisplayNameValidationError('displayName is required',getData,$credentials:event.credentials,$organization:event.organization);
      }
      
 else       if(event.credentials?.phoneNumber?.isEmpty==true){
        yield SignupCredentialsPhoneNumberValidationError('phoneNumber is required',getData,$credentials:event.credentials,$organization:event.organization);
      }
      
 else       if(event.credentials?.gender==null){
        yield SignupCredentialsGenderValidationError('gender is required',getData,$credentials:event.credentials,$organization:event.organization);
      }
      
 else       if(event.credentials?.dateOfBirth==null){
        yield SignupCredentialsDateOfBirthValidationError('dateOfBirth is required',getData,$credentials:event.credentials,$organization:event.organization);
      }
       
else 
            {
            try {
              await closeResultWrapper();
              resultWrapper = await client.signup(credentials:event.credentials,organization:event.organization);
              //listen for changes 
              resultWrapper.stream.listen((result) {
                //reset events before starting to emit new ones
                add(SignupReseted());
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
                    }).join('\n');
                  }
                  errors['message'] = message;
                }
                // convert result to data type expected by listeners
                AuthResult data;
                if (result.data != null) {
                  //add errors encountered to result
                  result.data.addAll(errors);
                  data = AuthResult.fromJson(result.data);
                } else if (errors.isNotEmpty) {
                // errors['data'] = null;
                  data = AuthResult.fromJson(errors);
                }
                if (result.hasException) {
                  if (result.exception.linkException != null) {
                    //emit error event
                    add(SignupErrored(data: data, message: data.message));
                  } else if (result.exception.graphqlErrors?.isNotEmpty == true) {
                    //emit failure event
                    add(SignupFailed(data: data, message: data.message));
                  }
                } else if (result.isLoading) {
                  //emit loading event
                  add(SignupIsLoading(data: data));
                } else if (result.isOptimistic) {
                  //emit optimistic event
                  add(SignupIsOptimistic(data: data));
                } else if (result.isConcrete) {
                  //emit completed event
                  add(SignupIsConcrete(data: data));
                }
              });
              resultWrapper.observableQuery.fetchResults();
            } catch (e) {
              //emit complete failure state;
              yield SignupError(data:state.data,message: e.toString());
            }
          }
        }

        closeResultWrapper() async {
          if (resultWrapper != null) {
            await resultWrapper.observableQuery.close();
          }
        }
       AuthResult get getData{
          return (state is SignupInitial)||(state is SignupError)?null:(state as dynamic)?.data;

        }
        @override
        Future<void> close() async {
          await closeResultWrapper();
          return super.close();
        }

      }
     