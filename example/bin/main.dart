import 'package:graphql/client.dart';
import 'package:graphql_to_dart/graphql_to_dart.dart';

import '../lib/graphql/models/location_create_input.dart';
import '../lib/graphql/models/service_category_list_response.dart';

void main(List<String> arguments) async {
  final HttpLink _httpLink = HttpLink(
    "http://localhost:3000/graphql",
  );
  final AuthLink _authLink = AuthLink(getToken: () async => 'xxxxx CONSUMER');
  var client = GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: _authLink.concat(_httpLink),
  );
  print(LocationCreateInput.fromJson({
    "lat": 8,
    "lon": 7.9,
  }).toJson());

  var query = gql("""
 query getCategories{
   findManyServiceCategory{
     status
     message
     data{
       __typename
       id
       name
       createdAt
       updatedAt
     }
   }
 }
 """);

  var result = await client.query(QueryOptions(document: query));
    var data=   ServiceCategoryListResponse.fromJson(result.data['findManyServiceCategory']);
  if (data.status) {
    data.data.forEach((c) {
      print(c.toJson());
    });
  }
}

void codeGen() {
  GraphQlToDart graphQlToDart = GraphQlToDart("graphql_config.yaml");
  graphQlToDart.init();
}
