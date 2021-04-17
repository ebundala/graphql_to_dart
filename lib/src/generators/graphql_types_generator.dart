import 'package:build/build.dart';
//import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as p;

import '../../graphql_to_dart.dart';

const graphqlExtension = ".graphql";
const astExtension = ".model.dart";

class GraphQlTypesBuilder implements Builder {
  final BuilderOptions config;
  GraphQlTypesBuilder(this.config);

  static AssetId fileAsset(BuildStep buildStep,String fileName) {
    return new AssetId(
      buildStep.inputId.package,
      p.join('lib', "$fileName$astExtension"),
    );
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        graphqlExtension: [astExtension],
      };

  Future<Map<String, String>> generateFiles() {
   GraphQlToDart graphQlToDart = GraphQlToDart("graphql_config.yaml");
  return graphQlToDart.init();
  }
  @override
  Future<void> build(BuildStep buildStep) async {
    final files = <String>[];
    final assets = <AssetId>[];
    final results=await generateFiles();
   // results.forEach((k,v){
   //   files.add(v);
  //    assets.add(fileAsset(buildStep,k));
   // });

   // for (var i = 0; i < files.length;i++) {
     // await buildStep.writeAsString(assets[i], files[i]);
   // }

    //return buildStep.writeAsString(output, files.join('\n'));
    return;
  }
}
