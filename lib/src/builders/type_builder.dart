import 'dart:io';

import 'package:graphql_to_dart/src/builders/keywords.dart';
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
  final Type type;
  final Config config;
  final StringBuffer stringBuffer = StringBuffer();
  final StringBuffer controllerBuffer = StringBuffer();
  List<LocalField> localFields = [];
  Map<String, String> outputs = {};
  TypeBuilder(this.type, this.config);
  bool hasExtensions = false;
  Future build() async {
    if (type.fields != null) {
      _addFields();
    }
    if (type.inputFields != null) {
      _addInputFields();
      _addGetFilesVariables();
      _addGetVariablesDefinitionsNodes();
      _addToValueNode();
    }
    if (type.enumValues != null) {
      _addEnumValues();
    } else {
      _addConstructor();
      _addFromJson();
      _addToJson();
      _addCopyWith();
      if (config.useEquatable) {
        var props = localFields
            .map((v) =>
                "${v.isList ? 'List.from(${to$(v.name)}??[])' : to$(v.name)}")
            .join(",");

        stringBuffer.writeln('');
        stringBuffer.writeln("List<Object?> get props => [$props];");
      }
      String current = stringBuffer.toString();
      stringBuffer.clear();
      if (type.inputFields != null) {
        final hasFile = type.inputFields!.where((e) {
          return _recursiveGetType(e.type)!.name == 'Upload';
        });

        if (hasFile.isNotEmpty) {
          stringBuffer
              .writeln('import "package:http/http.dart" show MultipartFile;');
        }
        stringBuffer.writeln('import "package:gql/ast.dart" as ast;');
      }
      if (config.useEquatable) {
        stringBuffer.writeln('import "package:equatable/equatable.dart";');
      }
      if (config.requiredInputField && type.inputFields != null) {
        // stringBuffer.writeln('import "package:meta/meta.dart";');
      }
      var imports = stringBuffer.toString();
      stringBuffer.clear();

      current = _wrapWith(
          current,
          "${imports}class ${type.name} ${config.useEquatable ? "extends Equatable" : ""} {",
          "}");
      if (type.inputFields == null) {
        current = '''
        ${current}
        ${_addExtensions()}
       
        ${_addController()}
        ''';
      }
      stringBuffer.write(current.toString());
      _addImports();
    }

    var path = "/${pascalToSnake(type.name!)}.dart".replaceAll(r"//", r"/");

    outputs[path] = stringBuffer.toString();
    outputs["/selection_node_data.dart"] = _addSelectionSetDataClass();
    //await saveToFile();
  }

  _addControllerValueChangeHandlers() {
    localFields.forEach((v) {
      if (!v.isList) {
        if (v.isEnum || v.isObject) {
          controllerBuffer.write("""
          void on${to$(v.name).pascalCase}Changed(${v.type} v) {
            if (value.${to$(v.name)} != v) {
              value = value.copyWith(${to$(v.name)}: v);
                ${to$(v.name)}Changed?.call(v);
            }
          }
          """);
        }
      } else {
        if (v.isObject) {
          controllerBuffer.write("""
          void on${to$(v.name).pascalCase}Changed(${v.type} v) {
                updated${to$(v.name).pascalCase}[v.id!] = v;
                var i = value.${to$(v.name)}?.indexWhere((e) => e.id == v.id)??-1;
                var list = List<${v.type}>.from(value.${to$(v.name)} ?? []);
                if (i >= 0) {
                  list[i] = v;
                } else {
                  list.add(v);
                   var selection = getSelectionNodeData("${v.name}")?.selectionSet;
                 ${to$(v.name)}Controller[v.id!] =
                 ${v.type}Controller(initialValue: v, selectionSet: selection!);
                }
                value = value.copyWith(${to$(v.name)}: list);
                
                  ${to$(v.name)}Changed?.call(v);
                
              }

              void on${to$(v.name).pascalCase}Removed(${v.type} v) {
                if (!v.isNew) {
                  deleted${to$(v.name).pascalCase}[v.id!] = v;
                }
                updated${to$(v.name).pascalCase}.remove(v.id!);
               ${to$(v.name)}Controller.remove(v.id!);
                value = value.copyWith(
                    ${to$(v.name)}:
                        value.${to$(v.name)}?.where((e) => e.id != v.id).toList() ??
                            []);

                  ${to$(v.name)}Removed?.call(v);
                
              }
          """);
        }
      }
    });
  }

  String _addController() {
    if (hasExtensions) {
      _addControllerValueChangeHandlers();
      return """class ${type.name}Controller extends ValueNotifier<${type.name}>{
          ${controllerBuffer.toString()}
          bool isInSelectionSet(String field){
          return selections.containsKey(field);
        }

     SelectionNodeData? getSelectionNodeData(String field){
          return selections[field];
        }

      Map<String,SelectionNodeData> initSelectionData(){
          var sel = selectionSet.selections;
          sel.forEach((el) {
            var e = el as FieldNode;
              selections[e.name.value]=SelectionNodeData(selected: true,selectionSet:e.selectionSet);
            });
            return selections;
        }
        }""";
    }
    return "";
  }

  String _addExtensions() {
    if (hasExtensions) {
      return """
        extension ${type.name}Ext on ${type.name} {
            bool get isInitialized{
              return isNew || isSaved;
            }
            bool get isSaved {              
              return id?.isNotEmpty == true && id?.contains("new") != true;             
            }

            bool get isNew {              
              return id?.isNotEmpty == true && id?.contains("new") == true;              
            }
          }
        """;
    }
    return "";
  }

  _addImports() {
    StringBuffer importBuffer = StringBuffer();
    localFields.unique<String>((field) => field.type).forEach((field) {
      if (field.isScalar &&
          (config.customScalarImplementationPaths?[field.type] as String?)
                  ?.isNotEmpty ==
              true) {
        final path = config.customScalarImplementationPaths?[field.type];

        importBuffer.writeln("import '${path}';");
      } else if ((field.isObject == true || field.isEnum) &&
          field.type != type.name) {
        if (config.dynamicImportPath) {
          // importBuffer.writeln(
          //   "import 'package:${config.packageName}/${config.modelsDirectoryPath.replaceAll(r"lib/", "")}/${pascalToSnake(field.type)}.dart';"
          //       .replaceAll(r"//", r"/"));
          importBuffer.writeln("import '${pascalToSnake(field.type)}.dart';");
        } else {
          importBuffer.writeln("import '${pascalToSnake(field.type)}.dart';"
              .replaceAll(r"//", r"/"));
        }
      }
    });
    if (type.inputFields == null && hasExtensions) {
      importBuffer.write("""
         import 'package:flutter/foundation.dart' show ValueNotifier;
         import 'package:flutter/widgets.dart' show TextEditingController;
         import 'package:gql/src/ast/ast.dart';
         import  'selection_node_data.dart';
          """);
    }
    String current = stringBuffer.toString();
    current = _wrapWith(current, importBuffer.toString() + "\n", "");
    stringBuffer.clear();
    stringBuffer.write(current);
  }

  _addToJson() {
    StringBuffer toJsonBuilder = StringBuffer();
    toJsonBuilder.writeln("Map<String,dynamic> _data = {};");
    localFields.forEach((field) {
      final nn = field.nonNull && !field.isList ? "" : "!";
      if (config.toJsonExcludeNullField) {
        toJsonBuilder.writeln(
            "${field.nonNull && !field.isList ? "" : "if(${to$(field.name)}!=null)"}");
      }
      if (field.isList == true) {
        if (field.type == "DateTime") {
          toJsonBuilder.writeln(
              "_data['${field.name}'] = List.generate(${to$(field.name)}?.length ?? 0, (index)=> ${to$(field.name)}![index].toString());");
        } else if (field.isObject == true ||
            field.isEnum == true ||
            config.customScalarImplementationPaths?[field.type] != null) {
          toJsonBuilder.writeln(
              "_data['${field.name}'] = List.generate(${to$(field.name)}?.length ?? 0, (index)=> ${to$(field.name)}![index].toJson());");
        } else {
          toJsonBuilder.writeln("_data['${field.name}'] = ${to$(field.name)};");
        }
      } else if (field.isObject == true ||
          field.isEnum == true ||
          config.customScalarImplementationPaths?[field.type] != null) {
        toJsonBuilder.writeln(
            "_data['${field.name}'] = ${to$(field.name)}$nn.toJson();");
      } else if (field.type == "DateTime") {
        toJsonBuilder.writeln(
            "_data['${field.name}'] = ${to$(field.name)}$nn.toString();");
      } else {
        toJsonBuilder.writeln("_data['${field.name}'] = ${to$(field.name)};");
      }
    });
    stringBuffer.writeln();
    toJsonBuilder.writeln("return _data;");
    stringBuffer.writeln();
    stringBuffer.write(_wrapWith(
        toJsonBuilder.toString(), "Map<String,dynamic> toJson(){", "}"));
  }

  _addCopyWith() {
    List copyWithArgs = [];
    List copyWithAssign = [];
    StringBuffer copyWith = StringBuffer();

    localFields.forEach((field) {
      copyWithArgs.add(field.toArgument());
      copyWithAssign.add(field.toCopyWithStatement());
    });

    copyWith.writeln("${type.name} copyWith({");
    copyWith.writeAll(copyWithArgs, ",");
    copyWith.writeln("})");
    copyWith.writeln("{");
    copyWith.write("return ${type.name}(");
    copyWith.writeAll(copyWithAssign, ",");
    copyWith.write(");");
    copyWith.writeln("}");
    stringBuffer.write(copyWith.toString());
  }

  _addFromJson() {
    StringBuffer fromJsonBuilder = StringBuffer();
    localFields.forEach((field) {
      if (field.isList == true) {
        fromJsonBuilder
            .write("${to$(field.name)}: json['${field.name}']!=null ?");
        if (field.isEnum) {
          fromJsonBuilder.write(
              "List.generate(json['${field.name}'].length, (index)=> ${field.type}Ext.fromJson(json['${field.name}'][index]))");
        } else if (field.isObject) {
          fromJsonBuilder.write(
              "List.generate(json['${field.name}'].length, (index)=> ${field.type}.fromJson(json['${field.name}'][index]))");
        } else if (field.type == 'Datetime') {
          fromJsonBuilder.write(
              "List.generate(json['${field.name}'].length, (index)=> DateTime.parse(json['${field.name}'][index]))");
        } else {
          if (config.customScalarImplementationPaths?[field.type] != null) {
            fromJsonBuilder.write(
                "List.generate(json['${field.name}'].length, (index)=> ${field.type}.fromJson(json['${field.name}'][index])) ");
          } else {
            fromJsonBuilder.write(
                "List.generate(json['${field.name}'].length, (index)=> json['${field.name}'][index] as ${field.type}) ");
          }
        }
        fromJsonBuilder.write(":null,");
//         fromJsonBuilder.write("""
// ${_to$(field.name)}: json['${field.name}']!=null ?
// ${field.object == true ? "List.generate(json['${field.name}'].length, (index)=> ${field.type}.fromJson(json['${field.name}'][index]))" : field.type == "DateTime" ? "List.generate(json['${field.name}'].length, (index)=> DateTime.parse(json['${field.name}'][index]))" : "json['${field.name}'].map<${field.type}>((o)=>${field.isEnum ? "${field.type}Ext.fromJson(o)" : "o"}).toList()"}: null,
//         """);
      } else if (field.isEnum == true) {
        fromJsonBuilder.writeln(
            "${to$(field.name)}:${field.nonNull ? "${field.type}Ext.fromJson(json['${field.name}'])" : "json['${field.name}']!=null ? ${field.type}Ext.fromJson(json['${field.name}']) : null"},");
      } else if (field.isObject == true ||
          config.customScalarImplementationPaths?[field.type] != null) {
        fromJsonBuilder.writeln(
            "${to$(field.name)}:${field.nonNull ? "${field.type}.fromJson(json['${field.name}'])" : "json['${field.name}']!=null ? ${field.type}.fromJson(json['${field.name}']) : null"},");
      } else if (field.type == "DateTime") {
        fromJsonBuilder.writeln(
            "${to$(field.name)}:${field.nonNull ? "DateTime.parse(json['${field.name}'])" : "json['${field.name}']!=null ? DateTime.parse(json['${field.name}']) : null"},");
      } else {
        if (field.type == 'double') {
          fromJsonBuilder.writeln(
              "${to$(field.name)}:${field.nonNull ? "json['${field.name}'].toDouble()" : "json['${field.name}']?.toDouble()"},");
        } else {
          fromJsonBuilder.writeln("${to$(field.name)}:json['${field.name}'],");
        }
      }
    });
    final str =
        _wrapWith(fromJsonBuilder.toString(), "return ${type.name}(", ");");
    stringBuffer.writeln();
    stringBuffer.writeln();
    stringBuffer.write(_wrapWith(
        str, "static ${type.name} fromJson(Map<dynamic, dynamic> json){", "}"));
    /* localFields.forEach((field) {
      if (config.requiredInputField && field.isInput && field.nonNull) {
        fromJsonBuilder.writeln("assert(json['${field.name}']!=null);");
      }
      if (field.list == true) {
        fromJsonBuilder.write("""
${_to$(field.name)} = json['${field.name}']!=null ?
${field.object == true ? "List.generate(json['${field.name}'].length, (index)=> ${field.type}.fromJson(json['${field.name}'][index]))" : field.type == "DateTime" ? "List.generate(json['${field.name}'].length, (index)=> DateTime.parse(json['${field.name}'][index]))" : "json['${field.name}'].map<${field.type}>((o)=>o.to${field.type}()).toList()"}: null;
        """);
      } //else if (field.isEnum) {
      //   // fromJsonBuilder.writeln("${field.name} = json['${field.name}'];");
      // }
      else if (field.object == true) {
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
    });*/
    //stringBuffer.writeln();
    //stringBuffer.writeln();
    // stringBuffer.write(_wrapWith(fromJsonBuilder.toString(),
    //     "${type.name}.fromJson(Map<String, dynamic> json){", "}"));
  }

  saveToFiles() async {
    outputs.forEach((k, v) async {
      File file = File(FileConstants().modelsDirectory!.path + "lib" + k);

      if (!(await file.exists())) {
        await file.create();
      }
      await file.writeAsString(v);
    });
    return null;
  }

  _addFields() {
    type.fields!.forEach((field) {
      if (!hasExtensions) {
        //TODO handle models with non id field such as device_id
        hasExtensions = field.name == 'id' && field.type.name == 'String';
      }
      _typeOrdering(field.type, field.name);
    });
  }

  _addInputFields() {
    type.inputFields!.forEach((field) {
      //pass true to indicate this is the input field
      _typeOrdering(field.type, field.name, true);
    });
  }

  _addEnumValues() {
    //stringBuffer.writeln('import "package:gql/ast.dart" as ast;');

    stringBuffer.write("""
        enum ${type.name}{
          ${type.enumValues!.map((e) => to$(e.name)).join(',\n')}
          }
          extension ${type.name}Ext on  ${type.name}{
            String toJson() {
              //final v = toString().split(".").last;
              switch(this){
                ${type.enumValues!.map((e) => 'case ${type.name}.${to$(e.name)}:\n return "${e.name}";').join('\n')}
                default:
                return '';
              }
              //return toString().split(".").last;
            }

            static ${type.name} fromJson(String json) {

               switch(json){
                ${type.enumValues!.map((e) => 'case "${e.name}":\n return ${type.name}.${to$(e.name)};').join('\n')}
             default:
                return ${type.name}.${to$(type.enumValues![0].name)};
              }
              //return ${type.name}.values.firstWhere((e) => e.toJson() == json);
            }
            }
        """);
  }

  _addSelectionSetDataClass() {
    return """
        import "package:gql/ast.dart";

         class SelectionNodeData{
              final bool selected;
              final SelectionSetNode? selectionSet;
              SelectionNodeData({required this.selected,this.selectionSet});
            }
         """;
  }

  _addConstructor() {
    StringBuffer constructorBuffer = StringBuffer();
    StringBuffer ctrBuffer = StringBuffer();
    StringBuffer ctrDisponseBuffer = StringBuffer();

    StringBuffer argumentsBuffer = StringBuffer();

    for (int i = 0; i < localFields.length; i++) {
      var field = localFields[i];
      if (config.requiredInputField && /*field.isInput &&*/ field.nonNull &&
          !field.isList) {
        constructorBuffer.write('required ');
      }
      constructorBuffer.write("this.${to$(field.name)}");
      if (i < localFields.length - 1) {
        constructorBuffer.write(",");
      }
      if (!field.isInput) {
        if (!field.isList) {
          if (field.isScalar &&
              ['int', 'double', 'String', 'DateTime'].contains(field.type)) {
            var isNumber = field.type == 'int' || field.type == 'double';
            var isDateTime = field.type == 'DateTime';
            var parser = isNumber
                ? "${field.type}.tryParse(${to$(field.name)}Controller?.text??'')"
                : isDateTime
                    ? "${field.type}.tryParse(${to$(field.name)}Controller?.text??'')"
                    : '${to$(field.name)}Controller?.text';
            ctrBuffer.write('''
          if(isInSelectionSet('${field.name}')){
              ${to$(field.name)}Controller = TextEditingController(text:"\${initialValue.${to$(field.name)}??''}")
                ..addListener(() {
                value = value.copyWith(${to$(field.name)}: ${parser});
              });
            }
            ''');
            ctrDisponseBuffer.write('''
           if(isInSelectionSet('${field.name}')){
              ${to$(field.name)}Controller?.dispose();
               
            }
          ''');
          } else if (field.isObject) {
            ctrBuffer.write('''
           if(isInSelectionSet('${field.name}')){
             var selected = getSelectionNodeData('${field.name}')?.selectionSet;
              ${to$(field.name)}Controller = ${field.type}Controller(initialValue:initialValue.${to$(field.name)}??${field.type}(),
              selectionSet:selected!);
              ${to$(field.name)}Controller?.addListener(() {
                var v=${to$(field.name)}Controller?.value;
                on${to$(field.name).pascalCase}Changed(v!);
              });
            }
          ''');
            ctrDisponseBuffer.write('''
           if(isInSelectionSet('${field.name}')){
              ${to$(field.name)}Controller?.dispose();
               
            }
          ''');
            argumentsBuffer.write('this.${to$(field.name)}Changed,');
          } else if (field.isEnum) {
            argumentsBuffer.write('this.${to$(field.name)}Changed,');
          }
        } else {
          if (field.isScalar) {
            ctrBuffer.write('''
            if(isInSelectionSet('${field.name}')){
                if (initialValue.${to$(field.name)}?.isNotEmpty == true) {                  
                  ${to$(field.name)}Controller.clear();
                  var values = initialValue.${to$(field.name)}?.map<TextEditingController>>((e){
                      return TextEditingController(text:"\${e}");
                      });
                  ${to$(field.name)}Controller.addAll(values);
                }
              }
          ''');
            ctrDisponseBuffer.write('''
           if(isInSelectionSet('${field.name}')){
              ${to$(field.name)}Controller.values.map((v)=>v.dispose()).toList();               
            }
          ''');
          }
          if (field.isObject) {
            ctrBuffer.write('''
             if(isInSelectionSet('${field.name}')){
                if (initialValue.${to$(field.name)}?.isNotEmpty == true) {
                  var selection = getSelectionNodeData('${field.name}')?.selectionSet;
                  ${to$(field.name)}Controller.clear();
                  var values = initialValue.${to$(field.name)}?.map<MapEntry<String, ${field.type}Controller>>((e) {
                          var controller = ${field.type}Controller(initialValue: e, selectionSet: selection!);
                          controller.addListener((){
                            on${to$(field.name).pascalCase}Changed(controller.value);
                          });
                    return MapEntry<String, ${field.type}Controller>(e.id!,controller);
                    });
                  ${to$(field.name)}Controller.addEntries(values??Iterable.empty());
                }
            }
          ''');
            ctrDisponseBuffer.write('''
           if(isInSelectionSet('${field.name}')){
              ${to$(field.name)}Controller.values.map((v)=>v.dispose()).toList(); 
            }
          ''');
            argumentsBuffer.write(
                'this.${to$(field.name)}Changed,this.${to$(field.name)}Removed,');
          }
        }
      }
    }
    stringBuffer.writeln(
        _wrapWith(constructorBuffer.toString(), "${type.name}({", "});"));
    // Controllers section

    controllerBuffer.write('''
    final ${type.name} initialValue;
    final SelectionSetNode selectionSet;
    final Map<String,SelectionNodeData> selections={};
    ${type.name}Controller({required this.initialValue,required this.selectionSet,${argumentsBuffer.toString()}}):super(initialValue){
     initSelectionData();
     ${ctrBuffer.toString()}
    }  
    @override
    dispose(){
      ${ctrDisponseBuffer.toString()}
      super.dispose();
    }  
    ''');
  }

  _addGetFilesVariables() {
    var fields = localFields
        .where((element) => element.isInput == true)
        .map((e) {
          final nn = e.nonNull ? "" : "!";
          if (e.type == TypeConverters().overrideType('Upload'))
            return """${e.nonNull && !e.isList ? "" : "if(${to$(e.name)} != null)"} {
              variables['\${field_name}_${e.name}'] = ${to$(e.name)};
            }""";
          else if (e.isList && e.isObject && !e.isScalar && !e.isEnum)
            return """if(${to$(e.name)} != null){
              int i=-1;
            ${to$(e.name)}!.forEach((e){
              i++;
              e.getFilesVariables(field_name:'\${field_name}_${e.name}_\$i',variables:variables);
              }
              );
            }""";
          else if (e.isObject && !e.isScalar && !e.isEnum)
            return """
            ${e.nonNull && !e.isList ? "" : "if(${to$(e.name)} != null)"}{
            ${to$(e.name)}${nn}.getFilesVariables(field_name:'\${field_name}_${e.name}',variables:variables);

            }
            """;
          else
            return null;
        })
        .where((element) => element != null)
        .join('\n');
    var fn = """
   Map<String, dynamic> getFilesVariables(
      {required String field_name, Map<String, dynamic>? variables}) {
    if (variables == null) {
      variables = Map();
    }
    ${fields}
   return variables;
  }
    """;
    stringBuffer.writeln();
    stringBuffer.write(fn);
  }

  _addGetVariablesDefinitionsNodes() {
    final fn = r"""
     List<ast.VariableDefinitionNode> getVariableDefinitionsNodes({
    required Map<String, dynamic> variables,
  }) {
    final List<ast.VariableDefinitionNode> vars = [];
    variables.forEach((key, value) {
      vars.add(ast.VariableDefinitionNode(
        variable: ast.VariableNode(name: ast.NameNode(value: key)),
        type: ast.NamedTypeNode(name: ast.NameNode(value: 'Upload'), isNonNull: true),
        defaultValue: ast.DefaultValueNode(value: null),
        directives: [],
      ));
    });
    return vars;
  }
    """;
    stringBuffer.writeln();
    stringBuffer.write(fn);
  }

  _getValueNodeType(
    LocalField field,
    String fieldName,
  ) {
    // var items = [];
    // items.fold<List>([], (previousValue, el) {
    //   var i = previousValue.length;
    //   previousValue.add(el);
    //   return previousValue;
    // });

    final nn = field.nonNull && !field.isList ? "" : "!";

    // if (field.name == 'in') {
    //   field.name;
    // }
    if (field.isEnum && !field.isList) {
      return """
      ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),

          value: ast.EnumValueNode(name: ast.NameNode(value: ${to$(field.name)}$nn.toJson())),

        )
      """;
    }

    if (field.isEnum && field.isList) {
      return """
       ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),

          value: ast.ListValueNode(values:[...${to$(field.name)}!
          .fold([],(v,e){
            // ignore: unused_local_variable
            int i = v.length;
             return [...v,${getScalarValueNode(field, 'e', '${fieldName}_\$i', true)})];
            })
            ],
            ),
          )        

      """;
    } else if (field.isList && field.isObject && !field.isScalar) {
      return """
       ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),

          value: ast.ListValueNode(values:[...${to$(field.name)}!
          .fold([],(v,e){
             // ignore: unused_local_variable
             int i = v.length;
             return [ ...v,e.toValueNode(field_name: '\${field_name}_${fieldName}_\$i')];
            
            }
          ,)
        ])

        )
      """;
    } else if (field.isList && field.isScalar && !field.isObject) {
      return """
      ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),

          value: ast.ListValueNode(values:[...${to$(field.name)}!
          .fold([],(v,e){
            // ignore: unused_local_variable
            int i = v.length;
            return [...v,${getScalarValueNode(field, 'e', '${fieldName}_\$i', true)}];
            }
            )
            ],
          )
        )        
        """;
    } else if (field.isObject && !field.isList && !field.isScalar) {
      return """
       ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),
         value: ${to$(field.name)}$nn.toValueNode(field_name: '\${field_name}_${fieldName}'),

         )
      """;
    } else if (field.isScalar) {
      if (field.type == TypeConverters().overrideType('Upload')) {
        return """
        ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),
          value: ast.VariableNode(name: ast.NameNode(value: '\${field_name}_${fieldName}')),
        )
          """;
      } else if (field.type == TypeConverters().overrideType('DateTime')) {
        return """
        ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),
          value: ast.StringValueNode(

              value: ${to$(field.name)}$nn.toIso8601String(), isBlock: false),

        )
       """;
      } else if (field.type == TypeConverters().overrideType('Int')) {
        return """
      ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),

          value: ast.IntValueNode(value: '\${${to$(field.name)}$nn}'),

        )
      """;
      } else if (field.type == TypeConverters().overrideType('Float')) {
        return """
      ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),

          value: ast.FloatValueNode(value: '\${${to$(field.name)}$nn}'),

        )
      """;
      } else if (field.type == TypeConverters().overrideType('String')) {
        return """
      ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),

          value: ast.StringValueNode(value: '\${${to$(field.name)}$nn}',isBlock:false),

        )
      """;
      } else if (field.type == TypeConverters().overrideType('Boolean')) {
        return """
      ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),
          value: ast.BooleanValueNode(value: ${to$(field.name)}$nn),
        )
      """;
      } else {
        if (config.customScalarImplementationPaths?[field.type] != null) {
          return """
      ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),
          value: ${to$(field.name)}$nn.toValueNode(field_name: '\${field_name}_${fieldName}'),
        )""";
        }
        return """
      ast.ObjectFieldNode(
          name: ast.NameNode(value: '${field.name}'),
          value: ast.NullValueNode(),

        )
      """;
      }
    }
  }

  String getScalarValueNode(LocalField field, String value, String fieldName,
      [inList = false]) {
    final nn = field.nonNull && !field.isList || inList ? "" : "!";

    if (field.type == TypeConverters().overrideType('Upload')) {
      return """
        ast.VariableNode(name: ast.NameNode(value: '\${name}_${fieldName}')
          """;
    } else if (field.type == TypeConverters().overrideType('DateTime')) {
      return """
         ast.StringValueNode(
              value: ${value}$nn.toIso8601String(), isBlock: false)
        
       """;
    } else if (field.type == TypeConverters().overrideType('Int')) {
      return """
       ast.IntValueNode(value: '\${${value}}')
      """;
    } else if (field.type == TypeConverters().overrideType('Float')) {
      return """
       ast.FloatValueNode(value: '\${${value}}')
      """;
    }
    if (field.type == TypeConverters().overrideType('String')) {
      return """
          ast.StringValueNode(value: ${value},isBlock:false)
      """;
    } else if (field.type == TypeConverters().overrideType('Boolean')) {
      return """
      ast.BooleanValueNode(value: ${value})
      """;
    } else if (field.isEnum) {
      return """
      ast.EnumValueNode(name: ast.NameNode(value: '\${${value}.toJson()}')
      """;
    } else {
      if (config.customScalarImplementationPaths?[field.type] != null) {
        return """      
          ${to$(field.name)}$nn.toValueNode(field_name: '\${field_name}_${fieldName}'),
        )""";
      }
      return """
       ast.NullValueNode()
      """;
    }
  }

  _addToValueNode() {
    var fields = localFields.map((e) {
      return """

      ${e.nonNull && e.isList == false ? "" : "if(${to$(e.name)}!=null)"}

       ${_getValueNodeType(e, '${e.name}')}
      """;
    }).join('\n,');

    final fn = """
    ast.ObjectValueNode toValueNode({required String field_name}) {
    return ast.ObjectValueNode(fields: [
      ${fields}
    ]);
  }
   """;
    stringBuffer.writeln();
    stringBuffer.write(fn);
  }

  // ignore: unused_element
  Type? _recursiveGetType(Type? t) {
    if (t!.kind == "NON_NULL") {
      t = t.ofType;
    }
    if (t!.kind == "LIST") {
      t = t.ofType;
    }
    if (t!.kind == "NON_NULL") {
      t = t.ofType;
    }
    return t;
  }

  _typeOrdering(Type? type, String? fieldName, [bool isInput = false]) {
    bool list = false;
    bool nonNull = false;
    LocalField localField;
    Type? t = type;
    if (t!.kind == "NON_NULL") {
      //mark only top level as non nullable
      nonNull = true;
      t = t.ofType;
    }
    if (t!.kind == "LIST") {
      list = true;
      t = t.ofType;
    }
    if (t!.kind == "NON_NULL") {
      t = t.ofType;
    }
    if (t!.kind == scalar) {
      localField = LocalField(
          name: fieldName ?? '',
          isList: list,
          nonNull: nonNull,
          isInput: isInput,
          isScalar: true,
          type: TypeConverters().overrideType(t.name!),
          isObject: false,
          isEnum: false);
      localFields.add(localField);
    } else if (t.kind == 'ENUM') {
      localField = LocalField(
          name: fieldName ?? "",
          isList: list,
          nonNull: nonNull,
          isInput: isInput,
          type: TypeConverters().overrideType(t.name!),
          isObject: false,
          isEnum: true);
      localFields.add(localField);
    } else {
      localField = LocalField(
          name: fieldName ?? '',
          isList: list,
          nonNull: nonNull,
          type: TypeConverters().overrideType(t.name!),
          isInput: isInput,
          isObject: true,
          isEnum: false);
      localFields.add(localField);
    }
    stringBuffer.writeln(localField.toDeclarationStatement());
    controllerBuffer.writeln(localField.toControllerDeclarationStatement());
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
  final bool isList;
  final bool nonNull;
  final String type;
  final bool isObject;
  final bool isEnum;
  final bool isInput;
  final bool isScalar;

  LocalField(
      {required this.name,
      required this.type,
      this.isList = false,
      this.isObject = false,
      this.isEnum = false,
      this.isInput = false,
      this.nonNull = false,
      this.isScalar = false});

  String toDeclarationStatement() {
    //return "final ${list ? 'List<${type}>' : '${type}'} ${_to$(name)};";
    final nn = '${nonNull ? "" : "?"}';

    return "final ${isList ? 'List<${type}>?' : '${type}$nn'} ${to$(name)};";
  }

  String toControllerDeclarationStatement() {
    if (!isList) {
      if (isScalar) {
        return 'TextEditingController? ${to$(name)}Controller;\n';
      } else if (isEnum) {
        return 'void Function(${type} value)? ${to$(name)}Changed;';
      } else if (isObject) {
        return '''
        ${type}Controller? ${to$(name).camelCase}Controller;
        void Function(${type} value)? ${to$(name)}Changed;
        ''';
      }
    } else {
      if (isScalar) {
        return 'final List<TextEditingController> ${to$(name)}Controller=[];\n';
      } else if (isEnum) {
        //TODO probably will need diferent implimentation of onchange
        return 'void Function(List<${type}> value)? ${to$(name)}Changed;\n';
      } else if (isObject) {
        return '''
        final Map<String,${type}> updated${to$(name).pascalCase}={};
        final Map<String,${type}> deleted${to$(name).pascalCase}={};
        void Function(${type} value)? ${to$(name)}Changed;
        void Function(${type} value)? ${to$(name)}Removed;
        // ${type} controllers
        final Map<String,${type}Controller> ${to$(name)}Controller={};
        ''';
      }
    }
    return '';
    // final nn = '${nonNull ? "" : "?"}';
    // return "final ${list ? 'List<${type}>?' : '${type}$nn'} ${to$(name)};";
  }

  String toArgument() {
    //return "final ${list ? 'List<${type}>' : '${type}'} ${_to$(name)};";
    final nn = '?'; //'${nonNull ? "" : "?"}';
    return "${isList ? 'List<${type}>?' : '${type}$nn'} ${to$(name)}";
  }

  String toCopyWithStatement() {
    return "${to$(name)}:${to$(name)}??this.${to$(name)}";
  }

  @override
  String toString() {
    return type;
  }
}

//helpers to rename fields starting with underscore/keywords
String to$(String name) {
  if (keywords[name] == true) {
    return "${name}\$";
  }
  return name.replaceAll(
      RegExp(
        r'_',
        multiLine: true,
      ),
      r"$");
}

String $to(String name) {
  if (name == "_all") {}
  var str = name.replaceAll(
      RegExp(
        r'$',
        multiLine: true,
      ),
      r"_");
  return str;
}
