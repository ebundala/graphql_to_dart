import 'package:gql/ast.dart';

Map<String, InputObjectTypeDefinitionNode> getInputsDef(DocumentNode document) {
  var s = InputInfoVisitor();
  document.visitChildren(s);
  //flatten input
  var inputs = s.accumulator
      .fold<Map<String, InputObjectTypeDefinitionNode>>({}, (p, n) {
    p.addAll(n);
    return p;
  });
  return inputs;
}

Map<String, ObjectTypeDefinitionNode> getTypesMapping(DocumentNode node) {
  var vs = ObjectInfoVisitor();
  node.visitChildren(vs);
  return vs.accumulator.fold<Map<String, ObjectTypeDefinitionNode>>({}, (p, n) {
    p.addAll(n);
    return p;
  });
}

List<String> getScalarsAndEnums(DocumentNode document) {
  var sc = ScalarInfoVisitor();
  document.visitChildren(sc);
  var scalars = ['Int', 'Float', 'String', 'ID', ...sc.accumulator];
  return scalars;
}

class OperationDefVisitor extends AccumulatingVisitor<OperationInfo> {
  final List<String> scalars;
  final List<String> enums;
  final Map<String, InputObjectTypeDefinitionNode> inputs;
  OperationDefVisitor(
      {required this.inputs, required this.scalars, required this.enums});
  @override
  void visitObjectTypeDefinitionNode(ObjectTypeDefinitionNode node) {
    if (node.name.value == 'Query' || node.name.value == 'Mutation') {
      //collect queries and mutations ;
      var v = OperationInfoVisitor(
          opType: node.name.value,
          scalars: scalars,
          inputs: inputs,
          enums: enums);
      node.visitChildren(v);
      accumulator.addAll(v.accumulator);
    }
    super.visitObjectTypeDefinitionNode(node);
  }
}

class OperationInfoVisitor extends AccumulatingVisitor<OperationInfo> {
  final String opType;
  final List<String> scalars;
  final List<String> enums;
  final Map<String, InputObjectTypeDefinitionNode> inputs;
  OperationInfoVisitor({
    required this.inputs,
    required this.opType,
    required this.scalars,
    required this.enums,
  }) {}
  @override
  void visitFieldDefinitionNode(FieldDefinitionNode node) {
    var name = node.name.value;
    var type = opType;
    var returnType = nodeType(node.type);
    var _isScalar = isScalar(returnType, scalars);
    var _isEnum = isEnum(returnType, enums);
    returnType = convertScalarsToDartTypes(_isScalar, returnType);
    var _isNonNull = isNonNull(node.type);
    var _isList = isList(node.type);
    var args = ArgsInfoVisitor(scalars: scalars, inputs: inputs);

    node.visitChildren(args);

    accumulator.add(OperationInfo(
        args: args.accumulator,
        name: name,
        type: type,
        returnType: returnType,
        isScalar: _isScalar,
        isEnum: _isEnum,
        isList: _isList,
        isNonNull: _isNonNull));
    super.visitFieldDefinitionNode(node);
  }
}

String nodeType(TypeNode node) {
  if (node is ListTypeNode) {
    return nodeType(node.type); //(node.type as NamedTypeNode).name.value;
  }
  return (node as NamedTypeNode).name.value;
}

String convertScalarsToDartTypes(isScalar, type) {
  var types = {"Int": 'int', "Float": 'double', 'ID': 'String'};
  return types[type] ?? type;
}

bool isList(TypeNode node) {
  if (node is ListTypeNode) {
    return true;
  }
  return false;
}

bool isNonNull(TypeNode node) {
  // if (node is ListTypeNode) {
  //   return (node.type as NamedTypeNode).isNonNull;
  // }
  if (node.isNonNull) return true;
  return false;
}

bool isScalar(String type, List<String> scalars) {
  return scalars.contains(type);
}

bool isEnum(String type, List<String> enums) {
  return enums.contains(type);
}

class ScalarInfoVisitor extends AccumulatingVisitor<String> {
  @override
  void visitScalarTypeDefinitionNode(ScalarTypeDefinitionNode node) {
    accumulator.add(node.name.value);
    super.visitScalarTypeDefinitionNode(node);
  }

  @override
  void visitEnumTypeDefinitionNode(EnumTypeDefinitionNode node) {
    accumulator.add(node.name.value);
    super.visitEnumTypeDefinitionNode(node);
  }
}

class ObjectInfoVisitor
    extends AccumulatingVisitor<Map<String, ObjectTypeDefinitionNode>> {
  @override
  void visitObjectTypeDefinitionNode(ObjectTypeDefinitionNode node) {
    var k = node.name.value;
    accumulator.add({k: node});
    super.visitObjectTypeDefinitionNode(node);
  }
}

class InputInfoVisitor
    extends AccumulatingVisitor<Map<String, InputObjectTypeDefinitionNode>> {
  @override
  void visitInputObjectTypeDefinitionNode(InputObjectTypeDefinitionNode node) {
    var k = node.name.value;
    accumulator.add({k: node});
    super.visitInputObjectTypeDefinitionNode(node);
  }
}

class ArgsInfoVisitor extends AccumulatingVisitor<ArgsInfo> {
  final List<String> scalars;
  final Map<String, InputObjectTypeDefinitionNode> inputs;

  ArgsInfoVisitor({required this.scalars, required this.inputs});
  @override
  void visitInputValueDefinitionNode(InputValueDefinitionNode node) {
    var name = node.name.value;
    var type = nodeType(node.type);
    var _isScalar = isScalar(type, scalars);
    var _isNonNull = isNonNull(node.type);
    var _isList = isList(node.type);
    type = convertScalarsToDartTypes(_isScalar, type);

    var fv = ArgFieldInfoVisitor(scalars);
    var inputAst = inputs[type];

    inputAst?.visitChildren(fv);

    accumulator.add(ArgsInfo(
        fields: fv.accumulator,
        name: name,
        type: type,
        isScalar: _isScalar,
        isList: _isList,
        isNonNull: _isNonNull));
    super.visitInputValueDefinitionNode(node);
  }
}

class ArgFieldInfoVisitor extends AccumulatingVisitor<ArgFieldInfo> {
  final List<String> scalars;

  ArgFieldInfoVisitor(this.scalars);
  @override
  void visitInputValueDefinitionNode(InputValueDefinitionNode node) {
    var name = node.name.value;
    var type = nodeType(node.type);
    var _isScalar = isScalar(type, scalars);
    var _isNonNull = isNonNull(node.type);
    var _isList = isList(node.type);
    type = convertScalarsToDartTypes(_isScalar, type);

    accumulator.add(ArgFieldInfo(
        name: name,
        type: type,
        isScalar: _isScalar,
        isList: _isList,
        isNonNull: _isNonNull));
    super.visitInputValueDefinitionNode(node);
  }
}

class OperationInfo {
  final String name;
  final String type;
  final String returnType;
  final bool isNonNull;
  final bool isScalar;
  final bool isList;
  final List<ArgsInfo> args;
  final bool isEnum;
  OperationInfo({
    required this.name,
    required this.type,
    required this.returnType,
    required this.isNonNull,
    required this.isScalar,
    required this.isList,
    required this.args,
    required this.isEnum,
  });
}

class ArgsInfo {
  final String name;
  final bool isNonNull;
  final bool isScalar;
  final bool isList;
  final String type;
  final List<ArgFieldInfo> fields;

  ArgsInfo(
      {required this.name,
      required this.isNonNull,
      required this.isScalar,
      required this.isList,
      required this.type,
      required this.fields});
}

class ArgFieldInfo {
  final String name;
  final bool isNonNull;
  final bool isList;
  final bool isScalar;
  final String type;

  ArgFieldInfo(
      {required this.name,
      required this.isNonNull,
      required this.isList,
      required this.isScalar,
      required this.type});
}

class OperationAstInfo {
  final String name;
  final String operationName;
  final String returnType;
  final List<VariableInfo> variables;
  //final bool isNonNull;
  // final bool isScalar;
  final bool isList;
  OperationAstInfo(
      {required this.name,
      required this.isList,
      required this.returnType,
      required this.operationName,
      required this.variables});
}

class VariableInfo {
  final String name;
  final bool isNonNull;
  final bool isScalar;
  final bool isEnum;
  final bool isList;
  final String type;
  final List<ArgFieldInfo> fields;

  VariableInfo(
      {required this.name,
      required this.isNonNull,
      required this.isScalar,
      required this.isEnum,
      required this.isList,
      required this.type,
      required this.fields});
}

class OperationDefinitionASTVisitor
    extends AccumulatingVisitor<OperationAstInfo> {
  final List<OperationInfo> schemaInfo;
  final List<String> scalars;
  final List<String> enums;
  final Map<String, InputObjectTypeDefinitionNode> inputs;
  final Map<String, ObjectTypeDefinitionNode> types;

  OperationDefinitionASTVisitor(
      {required this.schemaInfo,
      required this.types,
      required this.scalars,
      required this.inputs,
      required this.enums});
  String getOperationName(OperationDefinitionNode node) {
    SelectionNode? field = node.selectionSet.selections.firstWhere((v) {
      if (v is FieldNode) {
        if (v.selectionSet != null) {
          return true;
        }
      }
      return false;
    }, orElse: () => FieldNode(name: NameNode(value: 'Unknown')));
    var fieldName = (field as FieldNode).name.value;
    return fieldName;
  }

  String getReturnType(String operationName) {
    var info = schemaInfo.firstWhere((v) {
      return v.name == operationName;
    },
        orElse: () => OperationInfo(
            name: 'unkown',
            type: "unknown",
            returnType: "unknown",
            isNonNull: false,
            isScalar: true,
            isList: false,
            isEnum: false,
            args: <ArgsInfo>[]));
    return info.returnType;
  }

  bool _isList(String type) {
    final o = types[type];
    var field = o?.fields.firstWhere((i) => i.name.value == 'data',
        orElse: () => FieldDefinitionNode(
            name: NameNode(value: 'Unknown'),
            type: NamedTypeNode(name: NameNode(value: 'Unknown'))));
    if (field != null) return isList(field.type);
    return false;
  }

  @override
  void visitOperationDefinitionNode(OperationDefinitionNode node) {
    var name = node.name!.value;
    var operationName = getOperationName(node);
    var returnType = getReturnType(operationName);
    var isList = _isList(returnType);
    var vs = VariableVisitor(inputs: inputs, scalars: scalars, enums: enums);
    node.visitChildren(vs);
    var variables = vs.accumulator;

    accumulator.add(OperationAstInfo(
        name: name,
        returnType: returnType,
        operationName: operationName,
        isList: isList,
        variables: variables));
    super.visitOperationDefinitionNode(node);
  }
}

class VariableVisitor extends AccumulatingVisitor<VariableInfo> {
  final List<String> scalars;
  final List<String> enums;
  final Map<String, InputObjectTypeDefinitionNode> inputs;
  VariableVisitor(
      {required this.inputs, required this.scalars, required this.enums});

  @override
  void visitVariableDefinitionNode(VariableDefinitionNode node) {
    var name = node.variable.name.value;
    var type = nodeType(node.type);
    var _isScalar = isScalar(type, scalars);
    var _isEnum = isEnum(type, enums);
    var _isNonNull = isNonNull(node.type);
    var _isList = isList(node.type);

    type = convertScalarsToDartTypes(_isScalar, type);

    var fv = ArgFieldInfoVisitor(scalars);
    var inputAst = inputs[type];
    inputAst?.visitChildren(fv);
    accumulator.add(VariableInfo(
        name: name,
        isList: _isList,
        isScalar: _isScalar,
        isNonNull: _isNonNull,
        isEnum: _isEnum,
        type: type,
        fields: fv.accumulator));
    super.visitVariableDefinitionNode(node);
  }
}

List<OperationAstInfo> getOperationInfoFromAst({
  required DocumentNode document,
  required List<String> scalars,
  required List<String> enums,
  required List<OperationInfo> info,
  required Map<String, InputObjectTypeDefinitionNode> inputs,
  required Map<String, ObjectTypeDefinitionNode> types,
}) {
  var vs = OperationDefinitionASTVisitor(
      inputs: inputs,
      types: types,
      scalars: scalars,
      schemaInfo: info,
      enums: enums);
  document.visitChildren(vs);
  return vs.accumulator;
}
