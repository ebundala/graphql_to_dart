part of 'signup_bloc.dart';

extension on GraphQLClient {
  Future<OperationResult> signup(
      {@required SignupInput credentials,
      OrganizationCreateWithoutOwnerInput organization}) async {
    final Map<String, dynamic> vars = {};
    if (credentials != null) {
      vars["credentials"] = credentials.toJson();
    }
    if (organization != null) {
      vars["organization"] = organization.toJson();
    }
    List<ArgumentInfo> argsInfo = [
      if (credentials != null)
        ArgumentInfo(name: 'credentials', value: credentials)
    ];
    final doc =
        transform(document, [NormalizeArgumentsVisitor(args: argsInfo)]);
    final result = await runObservableOperation(
      this,
      document: doc,
      variables: credentials.getFilesVariables(name: 'credentials'),
    );

    var stream = result.stream.map((res) {
      var data = getDataFromField('signup', res);
      res.data = data;
      return res;
    });
    return OperationResult(
        isObservable: true, observableQuery: result, stream: stream);
  }

  //refetch fn
  void signupRetry(ObservableQuery observableQuery) {
    if (observableQuery.isRefetchSafe) observableQuery.refetch();
  }

  //load more fn
  void signupLoadMore(ObservableQuery observableQuery,
      {@required SignupInput credentials,
      OrganizationCreateWithoutOwnerInput organization}) {
    final Map<String, dynamic> vars = {};
    if (credentials != null) {
      vars["credentials"] = credentials.toJson();
    }
    if (organization != null) {
      vars["organization"] = organization.toJson();
    }
    observableQuery.fetchMore(
      FetchMoreOptions(
        document: document,
        variables: vars,
        updateQuery: (p, n) {
          if (p['data'] is List && n['data'] is List) {
            (p['data'] as List).addAll((n['data'] as List));
            return p;
          }
          return n;
        },
      ),
    );
  }
}
