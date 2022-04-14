import 'dart:developer';
import 'dart:io';

import 'package:graphql_to_dart/src/constants/files.dart';
import 'package:yaml/yaml.dart';
//import 'package:yaml/yaml.dart';

class Config {
  late String graphQLEndpoint;
//  String queriesFilePath;
//  String mutationsFilePath;
//  String subscriptionsFilePath;
  late String packageName;
  late String modelsDirectoryPath;
  late bool dynamicImportPath;
  late bool toJsonExcludeNullField;
  late bool useEquatable;
  YamlMap? typeOverride;
  late bool requiredInputField;
  late String schemaPath;
  late String helperPath;
  late String modelsImportPath;
  Config();
  Config.fromJson(Map map) {
    graphQLEndpoint = map['graphql_endpoint'].toString();
//    queriesFilePath = map['queries_file_path']?.toString();
//    mutationsFilePath = map['mutations_file_path']?.toString();
//    subscriptionsFilePath = map['subscriptions_file_path']?.toString();
    modelsDirectoryPath = map['models_directory_path'].toString();
    dynamicImportPath =
        map['dynamic_import_path']?.toString() == 'false' ? false : true;
    toJsonExcludeNullField =
        map['to_json_exclude_null_field'].toString() == 'false' ? false : true;
    useEquatable = map['use_equatable'].toString() == 'false' ? false : true;
    requiredInputField =
        map['required_input_field'].toString() == 'false' ? false : true;
    packageName = map['package_name'].toString();

    typeOverride = map['type_override'];
    schemaPath = map['schema_path'].toString();

    helperPath = map['helper_path'].toString();

    modelsImportPath = map["models_import_path"].toString();
  }
  Future<ValidationResult> validate() async {
//    File queriesFile = File(queriesFilePath);
//    File mutationsFile = File(mutationsFilePath);
//    File subscriptionsFile = File(subscriptionsFilePath);
    Directory modelsDirectory = Directory(modelsDirectoryPath);
    try {
//      if(!(await queriesFile.exists()))
//        await createRecursive(queriesFile);
//      if(!(await mutationsFile.exists()))
//        await createRecursive(mutationsFile);
//      if(!(await subscriptionsFile.exists()))
//        print(await createRecursive(subscriptionsFile));
      if (!(await modelsDirectory.exists())) {
        print(await createRecursive(modelsDirectory));
      }

      FileConstants().modelsDirectory = modelsDirectory;
//      FileConstants().queriesFile = queriesFile;
//      FileConstants().mutationsFile = mutationsFile;
//      FileConstants().subscriptionsFile = subscriptionsFile;
      return ValidationResult(hasError: false);
    } catch (e) {
      return ValidationResult(hasError: true, errorMessage: e.toString());
    }
  }

  Future<FileSystemEntity>? createRecursive(FileSystemEntity file) {
    if (file is File) {
      return file.create(recursive: true);
    } else {
      if (file is Directory) return file.create(recursive: true);
    }
    return null;
  }
}

class ValidationResult {
  bool hasError;
  String? errorMessage;

  ValidationResult({required this.hasError, this.errorMessage});
}
