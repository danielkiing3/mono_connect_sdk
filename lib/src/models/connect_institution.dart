import 'dart:convert';

import 'package:mono_connect_sdk/src/enums/connect_auth_method.dart';

class ConnectInstitution {
  final String id;
  final ConnectAuthMethod authMethod;

  const ConnectInstitution({required this.id, required this.authMethod});

  ConnectInstitution copyWith({String? id, ConnectAuthMethod? authMethod}) {
    return ConnectInstitution(
      id: id ?? this.id,
      authMethod: authMethod ?? this.authMethod,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'auth_method': authMethod.value};
  }

  factory ConnectInstitution.fromMap(Map<String, dynamic> map) {
    return ConnectInstitution(
      id: map['id'] as String,
      authMethod: ConnectAuthMethod.fromValue(map['auth_method'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ConnectInstitution.fromJson(String source) =>
      ConnectInstitution.fromMap(json.decode(source));

  @override
  String toString() => 'ConnectInstitution(id: $id, authMethod: $authMethod)';
}
