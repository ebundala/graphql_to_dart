part of 'signup_bloc.dart';

abstract class SignupState extends Equatable {
  @override
  List<Object> get props => [];
}

class SignupInitial extends SignupState {
  @override
  List<Object> get props => [];
}

class SignupSuccess extends SignupState {
  final AuthResult data;
  final String message;
  SignupSuccess({@required this.data, this.message});
  @override
  List<Object> get props => [data, message];
}

class SignupFailure extends SignupState {
  final AuthResult data;
  final String message;
  SignupFailure({@required this.data, this.message});
  @override
  List<Object> get props => [data, message];
}

class SignupInProgress extends SignupState {
  final AuthResult data;
  final String message;
  SignupInProgress({@required this.data, this.message});
  @override
  List<Object> get props => [data, message];
}
class SignupOptimistic extends SignupState {
  final AuthResult data;
  final String message;
  SignupOptimistic({@required this.data, this.message});
  @override
  List<Object> get props => [data, message];
}


class SignupError extends SignupState {
  final String message;
  SignupError({@required this.message});
  @override
  List<Object> get props => [message];
}

class SignupOrganizationNameValidationError extends SignupState {
  final AuthInput $credentials;
  final OrganizationCreateWithoutOwnerInput $organization;
  final AuthResult data;
  final String message;
  SignupOrganizationNameValidationError(this.message, this.data,
      {@required this.$credentials, this.$organization});
  @override
  List<Object> get props => [$credentials, $organization, message, data];
}

class SignupOrganizationLogoValidationError extends SignupState {
  final AuthInput $credentials;
  final OrganizationCreateWithoutOwnerInput $organization;
  final AuthResult data;
  final String message;
  SignupOrganizationLogoValidationError(this.message, this.data,
      {@required this.$credentials, this.$organization});
  @override
  List<Object> get props => [$credentials, $organization, message, data];
}

class SignupOrganizationLocationValidationError extends SignupState {
  final AuthInput $credentials;
  final OrganizationCreateWithoutOwnerInput $organization;
  final AuthResult data;
  final String message;
  SignupOrganizationLocationValidationError(this.message, this.data,
      {@required this.$credentials, this.$organization});
  @override
  List<Object> get props => [$credentials, $organization, message, data];
}
