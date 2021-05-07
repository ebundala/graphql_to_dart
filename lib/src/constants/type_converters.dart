class TypeConverters {
  TypeConverters._();
  static TypeConverters _instance = TypeConverters._();
  factory TypeConverters() => _instance;
  Map<String, String> nonObjectTypes = {
    "string": "String",
    "int": "int",
    "float": "double",
    "double": "double",
    "id": "String",
    "datetime": "DateTime",
    "date": "DateTime",
    "boolean": "bool",
    "bool": "bool",
    "uuid": "String"
  };
  String overrideType(String type) {
    return nonObjectTypes[type.toString().toLowerCase()] ?? type;
  }

  void overrideTypes(Map? newTypes) {
    newTypes?.forEach((key, value) {
      nonObjectTypes[key.toString().toLowerCase()] = value;
    });
  }
}
