import 'dart:io';

import 'package:graphql_to_dart/src/constants/files.dart';
import 'package:graphql_to_dart/src/constants/type_converters.dart';
import 'package:graphql_to_dart/src/models/config.dart';
import 'package:graphql_to_dart/src/models/graphql_types.dart';
import 'package:recase/recase.dart';
import 'package:graphql_to_dart/src/utils/helper_function.dart';

class TypeBuilder {
  static const String nonNull = "NON_NULL";
  static const String scalar = "SCALAR";
  static const String object = "OBJECT";
  final Types type;
  final Config config;
  final StringBuffer stringBuffer = StringBuffer();
  List<LocalField> localFields = [];
  Map<String, String> outputs = {};
  TypeBuilder(this.type, this.config);

  Future build() async {
    if (type.fields != null) {
      _addFields();
    }
    if (type.inputFields != null) {
      _addInputFields();
    }
    if (type.kind == 'ENUM') {
      _addEnumValues();
    } else {
      _addConstructor();
      _addFromJson();
      _addToJson();
      if (config.useEquatable) {
        var props = localFields
            .map((v) =>
                "${v.list ? 'List.from(${_to$(v.name)})' : _to$(v.name)}")
            .join(",");
        stringBuffer.writeln('');
        stringBuffer.writeln("List<Object> get props => [$props];");
      }
      String current = stringBuffer.toString();
      stringBuffer.clear();
      if (config.useEquatable) {
        stringBuffer.writeln('import "package:equatable/equatable.dart";');
      }
      if (config.requiredInputField) {
        stringBuffer.writeln('import "package:meta/meta.dart";');
      }
      var imports = stringBuffer.toString();
      stringBuffer.clear();
      current = _wrapWith(
          current,
          "${imports}class ${type.name} ${config.useEquatable ? "extends Equatable" : ""} {",
          "}");
      stringBuffer.write(current.toString());
      _addImports();
    }
    var path = "/${pascalToSnake(type.name)}.dart".replaceAll(r"//", r"/");
    outputs[path] = stringBuffer.toString();
    //await saveToFile();
  }

  _addImports() {
    StringBuffer importBuffer = StringBuffer();
    localFields.unique<String>((field) => field.type).forEach((field) {
      if (field.object == true) {
        if (config.dynamicImportPath) {
          importBuffer.writeln(
              "import 'package:${config.packageName}/${config.modelsDirectoryPath.replaceAll(r"lib/", "")}/${pascalToSnake(field.type)}.dart';"
                  .replaceAll(r"//", r"/"));
        } else {
          importBuffer.writeln("import '${pascalToSnake(field.type)}.dart';"
              .replaceAll(r"//", r"/"));
        }
      }
    });
    String current = stringBuffer.toString();
    current = _wrapWith(current, importBuffer.toString() + "\n", "");
    stringBuffer.clear();
    stringBuffer.write(current);
  }

  _addToJson() {
    StringBuffer toJsonBuilder = StringBuffer();
    toJsonBuilder.writeln("Map _data = {};");
    localFields.forEach((field) {
      if (config.toJsonExcludeNullField) {
        toJsonBuilder.writeln("if(${_to$(field.name)}!=null)");
      }
      if (field.list == true) {
        if (field.type == "DateTime") {
          toJsonBuilder.writeln(
              "_data['${field.name}'] = List.generate(${_to$(field.name)}?.length ?? 0, (index)=> ${_to$(field.name)}[index].toString());");
        } else if (field.object == true) {
          toJsonBuilder.writeln(
              "_data['${field.name}'] = List.generate(${_to$(field.name)}?.length ?? 0, (index)=> ${_to$(field.name)}[index].toJson());");
        } else {
          toJsonBuilder
              .writeln("_data['${field.name}'] = ${_to$(field.name)};");
        }
      } else if (field.object == true) {
        toJsonBuilder
            .writeln("_data['${field.name}'] = ${_to$(field.name)}?.toJson();");
      } else if (field.type == "DateTime") {
        toJsonBuilder.writeln(
            "_data['${field.name}'] = ${_to$(field.name)}?.toString();");
      } else {
        toJsonBuilder.writeln("_data['${field.name}'] = ${_to$(field.name)};");
      }
    });
    stringBuffer.writeln();
    toJsonBuilder.writeln("return _data;");
    stringBuffer.writeln();
    stringBuffer
        .write(_wrapWith(toJsonBuilder.toString(), "Map toJson(){", "}"));
  }

  _addFromJson() {
    StringBuffer fromJsonBuilder = StringBuffer();
    localFields.forEach((field) {
      if (config.requiredInputField && field.isInput && field.nonNull) {
        fromJsonBuilder.writeln("assert(json['${field.name}']!=null);");
      }
      if (field.list == true) {
        fromJsonBuilder.write("""
${_to$(field.name)} = json['${field.name}']!=null ?
${field.object == true ? "List.generate(json['${field.name}'].length, (index)=> ${field.type}.fromJson(json['${field.name}'][index]))" : field.type == "DateTime" ? "List.generate(json['${field.name}'].length, (index)=> DateTime.parse(json['${field.name}'][index]))" : "json['${field.name}'].map<${field.type}>((o)=>o.to${field.type}()).toList()"}: null;
        """);
      } else if (field.isEnum) {
        // fromJsonBuilder.writeln("${field.name} = json['${field.name}'];");
      } else if (field.object == true) {
        fromJsonBuilder.writeln(
            "${_to$(field.name)} = json['${field.name}']!=null ? ${field.type}.fromJson(json['${field.name}']) : null;");
      } else if (field.type == "DateTime") {
        fromJsonBuilder.writeln(
            "${_to$(field.name)} = json['${field.name}']!=null ? DateTime.parse(json['${field.name}']) : null;");
      } else {
        if (field.type == 'double') {
          fromJsonBuilder.writeln(
              "${_to$(field.name)} = json['${field.name}']?.toDouble();");
        } else {
          fromJsonBuilder
              .writeln("${_to$(field.name)} = json['${field.name}'];");
        }
      }
    });
    stringBuffer.writeln();
    stringBuffer.writeln();
    stringBuffer.write(_wrapWith(fromJsonBuilder.toString(),
        "${type.name}.fromJson(Map<String, dynamic> json){", "}"));
  }

  saveToFiles() async {
    outputs.forEach((k, v) async {
      File file = File(FileConstants().modelsDirectory.path + k);
      if (!(await file.exists())) {
        await file.create();
      }
      await file.writeAsString(stringBuffer.toString());
    });
    return null;
  }

  _addFields() {
    type.fields.forEach((field) {
      _typeOrdering(field.type, field.name);
    });
  }

  _addInputFields() {
    type.inputFields.forEach((field) {
      //pass true to indicate this is the input field
      _typeOrdering(field.type, field.name, true);
    });
  }

  _addEnumValues() {
    // stringBuffer.writeln("import 'package:flutter/foundation.dart';");
    stringBuffer.writeln(
        'enum ${type.name}{\n${type.enumValues.map((e) => e.name).join(',\n')}\n}');
//     stringBuffer.writeln('''
//     extension ${type.name}Index on ${type.name} {
//   // Overload the [] getter to get the name of the fruit.
//   operator[](String key) => (name){
//     switch(name) {
//      ${type.enumValues.map((e) => "case \'${e.name}\': return ${type.name}.${e.name};" ).join('\n')}
//       default:       throw RangeError("enum ${type.name} contains no value '\$name'");
//     }
//   }(key);
// }
//     ''');
  }

  _addConstructor() {
    StringBuffer constructorBuffer = StringBuffer();
    for (int i = 0; i < localFields.length; i++) {
      var field = localFields[i];
      if (config.requiredInputField && field.isInput && field.nonNull) {
        constructorBuffer.write('@required ');
      }
      constructorBuffer.write("this.${_to$(field.name)}");
      if (i < localFields.length - 1) {
        constructorBuffer.write(",");
      }
    }
    stringBuffer.writeln(
        _wrapWith(constructorBuffer.toString(), "${type.name}({", "});"));
  }

  _typeOrdering(Type type, String fieldName, [bool isInput = false]) {
    bool list = false;
    bool nonNull = false;
    LocalField localField;
    if (type.kind == "NON_NULL") {
      nonNull = true;
      type = type.ofType;
    }
    if (type.kind == "LIST") {
      list = true;
      type = type.ofType;
    }
    if (type.kind == "NON_NULL") {
      nonNull = true;
      type = type.ofType;
    }
    if (type.kind == scalar) {
      localField = LocalField(
          name: fieldName,
          list: list,
          nonNull: nonNull,
          isInput: isInput,
          type: TypeConverters().nonObjectTypes[type.name.toLowerCase()],
          object: false);
      localFields.add(localField);
    } else if (type.kind == 'ENUM') {
      localField = LocalField(
        name: fieldName,
        list: list,
        nonNull: nonNull,
        isInput: isInput,
        type: TypeConverters().nonObjectTypes['string'],
        object: false,
        /*isEnum: true*/
      );
      localFields.add(localField);
    } else {
      localField = LocalField(
          name: fieldName,
          list: list,
          nonNull: nonNull,
          type: type.name,
          isInput: isInput,
          object: true);
      localFields.add(localField);
    }
    stringBuffer.writeln(localField.toDeclarationStatement());
  }

  String _wrapWith(String input, String start, String end) {
    String updated = start + "\n" + input + "\n" + end;
    return updated;
  }

  String pascalToSnake(String pascalCasedString) {
    return ReCase(pascalCasedString).snakeCase;
  }
}

class LocalField {
  final String name;
  final bool list;
  final bool nonNull;
  final String type;
  final bool object;
  final bool isEnum;
  final bool isInput;

  LocalField(
      {this.name,
      this.list,
      this.type,
      this.object,
      this.isEnum = false,
      this.isInput = false,
      this.nonNull = false});

  String toDeclarationStatement() {
    return "${list ? "List<" : ""}${type ?? "var"}${list ? ">" : ""} ${_to$(name)};";
  }

  @override
  String toString() {
    // TODO: implement toString
    return type;
  }
}

//helpers to rename fields starting with underscore
_to$(String name) {
  return name.replaceAll(
      RegExp(
        r'_',
        multiLine: true,
      ),
      r"$");
}

$to_(String name) {
  if (name == "_all") {}
  var str = name.replaceAll(
      RegExp(
        r'$',
        multiLine: true,
      ),
      r"_");
  return str;
}
