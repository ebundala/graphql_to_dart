
import 'package:build/build.dart';
import 'package:graphql_to_dart/src/generators/graphql_types_generator.dart';
//import 'package:source_gen/source_gen.dart';

import 'ast_generator.dart';

Builder graphQlTypesBuilder(BuilderOptions options) =>
    GraphQlTypesBuilder(options);

Builder graphQlAstBuilder(BuilderOptions options) => AstGenerator();
