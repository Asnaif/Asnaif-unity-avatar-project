class AppUser {
  final String name;
  final String email;
  final String password;
  final String role;

  AppUser({
    required this.email,
    required this.password,
    required this.name,
    this.role = 'user',
  });

  bool isAdmin() => role == 'admin';
  bool isUser() => role == 'user';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: '', // Password should never be stored in Firestore
      role: map['role'] ?? 'user',
    );
  }
}
