import 'package:gql/ast.dart';

List<OperationInfo> getOperationsInfo(DocumentNode document) {
  var scalars = getScalarsAndEnums(document);
  var inputs = getInputsDef(document);
  var vs = OperationDefVisitor(scalars: scalars, inputs: inputs);
  document.visitChildren(vs);
  return vs.accumulator;
}

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

List<String> getScalarsAndEnums(DocumentNode document) {
  var sc = ScalarInfoVisitor();
  document.visitChildren(sc);
  var scalars = ['Int', 'Float', 'String', 'ID', ...sc.accumulator];
  return scalars;
}

class OperationDefVisitor extends AccumulatingVisitor<OperationInfo> {
  final List<String> scalars;
  final Map<String, InputObjectTypeDefinitionNode> inputs;
  OperationDefVisitor({this.inputs, this.scalars});
  @override
  void visitObjectTypeDefinitionNode(ObjectTypeDefinitionNode node) {
    if (node.name.value == 'Query' || node.name.value == 'Mutation') {
      //collect queries and mutations ;
      var v = OperationInfoVisitor(
          opType: node.name.value, scalars: scalars, inputs: inputs);
      node.visitChildren(v);
      accumulator.addAll(v.accumulator);
    }
    super.visitObjectTypeDefinitionNode(node);
  }
}

class OperationInfoVisitor extends AccumulatingVisitor<OperationInfo> {
  final String opType;
  final List<String> scalars;
  final Map<String, InputObjectTypeDefinitionNode> inputs;
  OperationInfoVisitor({
    this.inputs,
    this.opType,
    this.scalars,
  }) {}
  @override
  void visitFieldDefinitionNode(FieldDefinitionNode node) {
    var name = node.name.value;
    var type = opType;
    var returnType = nodeType(node.type);
    var _isScalar = isScalar(returnType, scalars);
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
        isList: _isList,
        isNonNull: _isNonNull));
    super.visitFieldDefinitionNode(node);
  }
}

String nodeType(TypeNode node) {
  if (node is ListTypeNode) {
    return (node.type as NamedTypeNode).name.value;
  }
  return (node as NamedTypeNode).name.value;
}

bool isList(TypeNode node) {
  if (node is ListTypeNode) {
    return true;
  }
  return false;
}

bool isNonNull(TypeNode node) {
  if (node.isNonNull) return true;
  if (node is ListTypeNode) {
    return (node.type as NamedTypeNode).isNonNull;
  }
  return false;
}

bool isScalar(String type, List<String> scalars) {
  return scalars.contains(type);
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

  ArgsInfoVisitor({this.scalars, this.inputs});
  @override
  void visitInputValueDefinitionNode(InputValueDefinitionNode node) {
    var name = node.name.value;
    var type = nodeType(node.type);
    var _isScalar = isScalar(type, scalars);
    var _isNonNull = isNonNull(node.type);
    var _isList = isList(node.type);
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
  OperationInfo({
    this.name,
    this.type,
    this.returnType,
    this.isNonNull,
    this.isScalar,
    this.isList,
    this.args,
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
      {this.name,
      this.isNonNull,
      this.isScalar,
      this.isList,
      this.type,
      this.fields});
}

class ArgFieldInfo {
  final String name;
  final bool isNonNull;
  final bool isList;
  final bool isScalar;
  final String type;

  ArgFieldInfo(
      {this.name, this.isNonNull, this.isList, this.isScalar, this.type});
}
