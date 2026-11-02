import 'package:heliumapp/data/models/auth/oauth_scope_model.dart';
import 'package:heliumapp/data/models/base_model.dart';

class ConnectedAppModel extends BaseModel {
  final String name;
  final List<OAuthScopeModel> scopes;
  final DateTime? lastUsedAt;

  ConnectedAppModel({
    required super.id,
    required this.name,
    required this.scopes,
    this.lastUsedAt,
  });

  factory ConnectedAppModel.fromJson(Map<String, dynamic> json) {
    return ConnectedAppModel(
      id: json['id'],
      name: json['name'],
      scopes: (json['scopes'] as List<dynamic>)
          .map((scope) => OAuthScopeModel.fromJson(scope))
          .toList(),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
    );
  }
}
