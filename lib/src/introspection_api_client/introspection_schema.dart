import 'package:gql/ast.dart';
import 'package:graphql_to_dart/graphql_to_dart.dart';

class IntrospectionSchema {
  List<InputObjectTypeDefinitionNode> inputs;
  List<ScalarTypeDefinitionNode> scalars;
  List<InterfaceTypeDefinitionNode> interfaces;
  List<UnionTypeDefinitionNode> unions;
  List<ObjectTypeDefinitionNode> objects;
  List<EnumTypeDefinitionNode> enums;
  //TODO handle directives

  IntrospectionSchema(
      {required this.inputs,
      required this.interfaces,
      required this.enums,
      required this.objects,
      required this.scalars,
      required this.unions});

  static IntrospectionSchema fromDocumentNode(DocumentNode doc) {
    return IntrospectionSchema(
        inputs:
            doc.definitions.whereType<InputObjectTypeDefinitionNode>().toList(),
        scalars: doc.definitions.whereType<ScalarTypeDefinitionNode>().toList(),
        enums: doc.definitions.whereType<EnumTypeDefinitionNode>().toList(),
        unions: doc.definitions.whereType<UnionTypeDefinitionNode>().toList(),
        objects: doc.definitions.whereType<ObjectTypeDefinitionNode>().toList(),
        interfaces:
            doc.definitions.whereType<InterfaceTypeDefinitionNode>().toList());
  }

  static IntrospectionSchema fromTypes(List<Type> types) {
    //final i = types.where((e) => e.name == "SignupInput").toList();

    TypeNode getNodeType(Type type, [bool? non_null]) {
      bool nonNullable = non_null ?? type.kind == "NON_NULL";
      if (type.kind == "LIST") {
        return ListTypeNode(
            type: getNodeType(type.ofType!), isNonNull: nonNullable);
      } else if (type.ofType != null) {
        return getNodeType(type.ofType!, nonNullable);
      } else
        return NamedTypeNode(
            name: NameNode(
              value: type.name,
            ),
            isNonNull: nonNullable);
    }

    final inputs = types.where((e) => e.kind == "INPUT_OBJECT").map((e) {
      return InputObjectTypeDefinitionNode(
          name: NameNode(value: e.name),
          fields: e.inputFields!
              .map<InputValueDefinitionNode>(
                (f) => InputValueDefinitionNode(
                  name: NameNode(value: f.name),
                  type: getNodeType(f.type),
                ),
              )
              .toList());
    }).toList();

    final scalars = types.where((e) => e.kind == "SCALAR").map((e) {
      return ScalarTypeDefinitionNode(
        name: NameNode(value: e.name),
      );
    }).toList();

    final enums = types.where((e) => e.kind == "ENUM").map((e) {
      return EnumTypeDefinitionNode(
        name: NameNode(value: e.name),
        values: e.enumValues!.map(
          (e) {
            return EnumValueDefinitionNode(
              name: NameNode(value: e.name),
            );
          },
        ).toList(),
      );
    }).toList();
    final objects = types.where((e) => e.kind == "OBJECT").map((e) {
      return ObjectTypeDefinitionNode(
        name: NameNode(value: e.name),
        interfaces: e.interfaces!
            .map<NamedTypeNode>((i) => getNodeType(i) as NamedTypeNode)
            .toList(),
        fields: e.fields!.map(
          (e) {
            return FieldDefinitionNode(
                name: NameNode(value: e.name),
                type: getNodeType(e.type),
                args: e.args.map((e) {
                  return InputValueDefinitionNode(
                    name: NameNode(value: e.name),
                    type: getNodeType(e.type),
                  );
                }).toList());
          },
        ).toList(),
      );
    }).toList();
    final interfaces = types.where((e) => e.kind == "INTERFACE").map((e) {
      return InterfaceTypeDefinitionNode(
        name: NameNode(value: e.name),
        fields: e.fields!.map(
          (e) {
            return FieldDefinitionNode(
                name: NameNode(value: e.name),
                type: getNodeType(e.type),
                args: e.args.map((e) {
                  return InputValueDefinitionNode(
                    name: NameNode(value: e.name),
                    type: getNodeType(e.type),
                  );
                }).toList());
          },
        ).toList(),
      );
    }).toList();
    final unions = types.where((e) => e.kind == "UNION").map((e) {
      return UnionTypeDefinitionNode(
        name: NameNode(value: e.name),
        types: e.possibleTypes!
            .map((i) => getNodeType(i) as NamedTypeNode)
            .toList(),
      );
    }).toList();

    return IntrospectionSchema(
        inputs: inputs,
        interfaces: interfaces,
        unions: unions,
        enums: enums,
        scalars: scalars,
        objects: objects);
  }

  Map<String, InputObjectTypeDefinitionNode> inputsMap() {
    var _inputs = <String, InputObjectTypeDefinitionNode>{};
    inputs.forEach((e) {
      _inputs[e.name.value] = e;
    });
    return _inputs;
  }

  Map<String, ObjectTypeDefinitionNode> objectsMap() {
    var _objects = <String, ObjectTypeDefinitionNode>{};
    objects.forEach((e) {
      _objects[e.name.value] = e;
    });
    return _objects;
  }

  List<String> scalarsAndEnums() {
    return [
      ...scalars.map<String>((e) => e.name.value).toList(),
      ...enums.map<String>((e) => e.name.value).toList()
    ];
  }

  List<OperationInfo> operationInfo() {
    return objects
        .where((e) =>
            e.name.value == "Query" ||
            e.name.value == "Mutation" ||
            e.name.value == "Subscription")
        .map<List<OperationInfo>>((e) {
      final v = OperationInfoVisitor(
          inputs: inputsMap(),
          opType: e.name.value,
          scalars: scalarsAndEnums());
      e.visitChildren(v);
      return v.accumulator;
    }).fold<List<OperationInfo>>([], (p, n) {
      p.addAll(n);
      return p;
    });
  }

  DocumentNode toDocumentNode() {
    return DocumentNode(definitions: [
      ...inputs,
      ...interfaces,
      ...unions,
      ...objects,
      ...scalars
    ]);
  }
}
