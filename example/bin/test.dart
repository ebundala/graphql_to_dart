import 'dart:io';
import 'package:example/graphql/clients/signup/signup_bloc.dart';
import 'package:example/graphql/models/signup_input.dart';
import 'package:graphql/client.dart';
import "package:http/http.dart" show MultipartFile;

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

  var sub = bloc.stream.listen((state) {
    print(state);
  }, onError: (e) {
    print(e);
  });

  bloc.add(
    SignupExcuted(
      credentials: SignupInput(
          email: "ebundala+27@gmail.com",
          password: 'password',
          displayName: "Musa dart bloc",
          dateOfBirth: DateTime(2021),
          gender: 'MALE',
          phoneNumber: '+2550714226465',
          avator: MultipartFile.fromString('', 'text here',
              filename: 'avator.txt')),
    ),
  );

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
