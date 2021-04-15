import 'package:example/graphql/models/aggregate_attachment_response.dart';
import 'package:graphql_to_dart/graphql_to_dart.dart';

void main(List<String> arguments) {
  //print(AggregateAttachmentResponse.fromJson({"status":true}).toJson());
  GraphQlToDart graphQlToDart = GraphQlToDart("graphql_config.yaml");
  graphQlToDart.init();
  print('Hello world!');
}
