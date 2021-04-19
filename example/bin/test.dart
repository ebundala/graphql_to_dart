import 'dart:io';
import 'package:example/generated_clients/signup/signup_bloc.dart';
import 'package:example/graphql/models/auth_input.dart';
import 'package:graphql/client.dart';

main(List<String> args) async {
  final HttpLink _httpLink = HttpLink(
    "http://localhost:3000/graphql",
  );
  final AuthLink _authLink = AuthLink(getToken: () async => 'xxxxx ANONYMOUS');
  var client = GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: _authLink.concat(_httpLink),
  );

  var bloc = SignupBloc(client: client);
  var sub = bloc.listen((state) {
    print(state);
  }, onError: (e) {
    print(e);
  });

  bloc.add(SignupExcuted(
      credentials: AuthInput(
    email: "ebundala+27@gmail.com",
    password: 'password',
    displayName: "Musa dart bloc",
  )));

  await sub.asFuture().then((r) {
    print(r);
  }).catchError((e) {
    print(e);
  });
}

String fileName(String operationName, String name, [String ext = '.dart']) {
  return "/${operationName}_$name$ext";
}

saveFile(
  String fileName,
  String content,
) async {
  Directory current = Directory.current;
  File file = File(current.path + fileName);
  if (!(await file.exists())) {
    await file.create();
  }
  await file.writeAsString(content);
  return null;
}

class BlocBuilder {}
