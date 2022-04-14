class GraphQLSchema {
  late List<Type> types;
  late Type queryType;
  late Type mutationType;
  late Type subscriptionType;

  GraphQLSchema({required this.types});

  GraphQLSchema.fromJson(Map<String, dynamic> json) {
    if (json['types'] != null) {
      types = <Type>[];
      json['types'].forEach((v) {
        types.add(Type.fromJson(v));
      });
    }
    if (json['queryType'] != null) {
      queryType = Type.fromJson(json['queryType']);
    }
    if (json['mutationType'] != null) {
      mutationType = Type.fromJson(json['mutationType']);
    }
    if (json['subscriptionType'] != null) {
      subscriptionType = Type.fromJson(json['subscriptionType']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['types'] = this.types.map((v) => v.toJson()).toList();
    return data;
  }
}

class Type {
  String kind;
  String? name;
  Type? ofType;
  List<Field>? fields;
  List<InputValue>? inputFields;
  List<EnumValue>? enumValues;
  List<Type>? interfaces;
  List<Type>? possibleTypes;
  Type(
      {required this.kind,
      required this.name,
      this.fields,
      this.enumValues,
      this.inputFields,
      this.interfaces,
      this.possibleTypes,
      this.ofType});

  static Type fromJson(Map<String, dynamic> json) {
    String _kind = json['kind'];
    String? _name = json['name'];
    Type? _ofType;
    List<Field>? _fields;
    List<InputValue>? _inputFields;
    List<EnumValue>? _enumValues;
    List<Type>? _interfaces;
    List<Type>? _possibleTypes;
    if (json['fields'] != null) {
      _fields = <Field>[];
      json['fields'].forEach((v) {
        _fields!.add(Field.fromJson(v));
      });
    }
    if (json['inputFields'] != null) {
      _inputFields = <InputValue>[];
      json['inputFields'].forEach((v) {
        _inputFields!.add(InputValue.fromJson(v));
      });
    }
    if (json['enumValues'] != null) {
      _enumValues = <EnumValue>[];
      json['enumValues'].forEach((v) {
        print(v);
        _enumValues!.add(EnumValue.fromJson(v));
      });
    }
    if (json['interfaces'] != null) {
      _interfaces = <Type>[];
      json['interfaces'].forEach((v) {
        _interfaces!.add(Type.fromJson(v));
      });
    }
    if (json['possibleTypes'] != null) {
      _possibleTypes = <Type>[];
      json['possibleTypes'].forEach((v) {
        _possibleTypes!.add(Type.fromJson(v));
      });
    }
    _ofType = json['ofType'] != null ? Type.fromJson(json['ofType']) : null;
    return Type(
        kind: _kind,
        name: _name,
        fields: _fields,
        enumValues: _enumValues,
        inputFields: _inputFields,
        interfaces: _interfaces,
        possibleTypes: _possibleTypes,
        ofType: _ofType);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.fields != null) {
      data['fields'] = this.fields!.map((v) => v.toJson()).toList();
    }
    data['kind'] = this.kind;
    data['name'] = this.name;
    data['ofType'] = this.ofType!.toJson();
    data["fields"] = this.fields!.map((e) => e.toJson()).toList();
    data["enumValues"] = this.enumValues!.map((e) => e.toJson());
    data["inputFields"] = this.inputFields!.map((e) => e.toJson());
    data["interfaces"] = this.interfaces!.map((e) => e.toJson());
    data["possibleTypes"] = this.possibleTypes!.map((e) => e.toJson());
    data["ofType"] = this.ofType!.toJson();
    return data;
  }
}

class Field {
  String? description;
  String name;
  Type type;
  List<InputValue> args;

  Field(
      {this.description,
      required this.name,
      required this.type,
      required this.args});

  static Field fromJson(Map<String, dynamic> json) {
    return Field(
        name: json["name"],
        type: Type.fromJson(json["type"]),
        args: json["args"]
            .map<InputValue>((v) => InputValue.fromJson(v))
            .toList());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['description'] = this.description;
    data['name'] = this.name;
    data["type"] = this.type.toJson();
    data["args"] = this.args.map((e) => e.toJson()).toList();
    return data;
  }
}

// class Type {
//   String? kind;
//   String? name;
//   Type? ofType;

//   Type({this.kind, this.name, this.ofType});

//   Type.fromJson(Map<String, dynamic> json) {
//     kind = json['kind'];
//     name = json['name'];
//     ofType = json['ofType'] != null ? Type.fromJson(json['ofType']) : null;
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['kind'] = this.kind;
//     data['name'] = this.name;
//     if (this.ofType != null) {
//       data['ofType'] = this.ofType!.toJson();
//     }
//     return data;
//   }
// }

class OfType {
  String? kind;
  String? name;

  OfType({this.kind, this.name});

  OfType.fromJson(Map<String, dynamic> json) {
    kind = json['kind'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['kind'] = this.kind;
    data['name'] = this.name;
    return data;
  }
}

class InputValue {
  String name;
  Type type;
  InputValue({required this.name, required this.type});
  static InputValue fromJson(Map<String, dynamic> json) {
    return InputValue(name: json["name"], type: Type.fromJson(json["type"]));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['type'] = this.type.toJson();
    data['name'] = this.name;
    return data;
  }
}

class EnumValue {
  String name;
  EnumValue({required this.name});

  static EnumValue fromJson(Map<String, dynamic> json) {
    return EnumValue(name: json["name"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['name'] = this.name;
    return data;
  }
}
