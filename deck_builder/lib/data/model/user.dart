class User {
  late String username;
  late String password;
  late String email;

  User( 
    {
      required this.username,
      required this.password,
      required this.email
    }
  );

  User.fromJson(Map<String, dynamic> parsedJson) {
    username = parsedJson['username'] as String? ?? '';
    password = parsedJson['password'] as String? ?? '';
    email = parsedJson['email'] as String? ?? '';
  }

   Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
    };
   }
}