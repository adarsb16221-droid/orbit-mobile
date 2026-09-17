class User {
  final String id;
  final String name;
  final String email;
  final String authProvider;
  final int orbitPoints;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.authProvider,
    required this.orbitPoints,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      authProvider: json['authProvider'] ?? 'local',
      orbitPoints: json['orbitPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'authProvider': authProvider,
      'orbitPoints': orbitPoints,
    };
  }
}
