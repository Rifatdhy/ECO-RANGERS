class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.isAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      // API Laravel mengirim 0 atau 1 untuk boolean
      isAdmin: (json['is_admin'] == 1 || json['is_admin'] == true),
    );
  }
}
