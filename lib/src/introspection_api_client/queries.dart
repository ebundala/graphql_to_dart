class Queries {
  static const String types = """
  {
  __schema {
    __typename
    types {
      ...typeFields
    }
    mutationType {
      ...typeFields
    }
    queryType {
      ...typeFields
    }
    subscriptionType {
      ...typeFields
    }
  }
}

fragment typeFields on __Type {
  __typename
  name
  kind

  ofType {
    __typename
    name
    kind
    ofType {
      name
      kind
      ofType {
        name
        kind
      }
    }
  }
  enumValues {
    __typename
    name
  }
  inputFields {
    __typename
    name
    description

    type {
      __typename
      name
      kind
      ofType {
        __typename
        name
        kind
        ofType {
          name
          kind
          ofType {
            name
            kind
          }
        }
      }
    }
  }
  fields {
    __typename
    name
    description
    args {
      __typename
      name
      description

      type {
        __typename
        name
        kind
        ofType {
          __typename
          name
          kind
          ofType {
            name
            kind
            ofType {
              name
              kind
            }
          }
        }
      }
    }
    type {
      __typename
      name
      kind
      ofType {
        __typename
        name
        kind
        ofType {
          __typename
          name
          kind
          ofType {
            __typename
            name
            kind
          }
        }
      }
    }
  }
  interfaces {
    __typename
    name
    kind

    ofType {
      __typename
      name
      kind
      ofType {
        name
        kind
        ofType {
          name
          kind
        }
      }
    }
    enumValues {
      __typename
      name
    }
    inputFields {
      __typename
      name
      description
      type {
        __typename
        name
        kind
        ofType {
          __typename
          name
          kind
          ofType {
            name
            kind
            ofType {
              name
              kind
            }
          }
        }
      }
    }
    fields {
      __typename
      name
      description
      args {
        __typename
      }
      type {
        __typename
        name
        kind
        ofType {
          __typename
          name
          kind
          ofType {
            __typename
            name
            kind
            ofType {
              __typename
              name
              kind
            }
          }
        }
      }
    }
  }
  possibleTypes {
    __typename
    name
    kind

    ofType {
      __typename
      name
      kind
      ofType {
        name
        kind
        ofType {
          name
          kind
        }
      }
    }
    enumValues {
      __typename
      name
    }
    inputFields {
      __typename
      name
      description
      type {
        __typename
        name
        kind
        ofType {
          __typename
          name
          kind
          ofType {
            name
            kind
            ofType {
              name
              kind
            }
          }
        }
      }
    }
    fields {
      __typename
      name
      description
      args {
        __typename
      }
      type {
        __typename
        name
        kind
        ofType {
          __typename
          name
          kind
          ofType {
            __typename
            name
            kind
            ofType {
              __typename
              name
              kind
            }
          }
        }
      }
    }
  }
}

  """;
}
