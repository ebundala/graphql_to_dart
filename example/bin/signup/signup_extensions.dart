part of 'signup_bloc.dart';

extension on GraphQLClient {
  Future<OperationResult> signup(
      {@required AuthInput credentials,
      OrganizationCreateWithoutOwnerInput organization}) async {
    final Map<String, dynamic> vars = {};
    if (credentials != null) {
      vars["credentials"] = credentials.toJson();
    }
    if (organization != null) {
      vars["organization"] = organization.toJson();
    }
    final result =
        await runObservableOperation(this, document: document, variables: vars);
    var stream = result.stream.map((res) {
      var data = getDataFromField('signup', res);
      res.data = data;
      return res;
    });
    return OperationResult(
        isObservable: true, observableQuery: result, stream: stream);
  }
}
