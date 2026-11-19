/// Perfil do usuário autenticado ou de um amigo da tribo.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
  });

  final String id;
  final String name;
  final String email;

  /// Caminho local de uma foto de avatar (opcional).
  final String? avatarPath;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  UserProfile copyWith({String? name, String? email, String? avatarPath}) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarPath: avatarPath ?? this.avatarPath,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatarPath': avatarPath,
  };

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
    id: json['id']! as String,
    name: json['name']! as String,
    email: (json['email'] as String?) ?? '',
    avatarPath: json['avatarPath'] as String?,
  );
}
