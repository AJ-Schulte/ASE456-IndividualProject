import 'package:pocketbase/pocketbase.dart';

/// ---- CONFIG ----
const pocketBaseUrl = 'http://127.0.0.1:8090';
const adminEmail = 'captrockstar007@gmail.com';
const adminPassword = 'Gintamaisthebest';

Future<void> main() async {
  final pb = PocketBase(pocketBaseUrl);

  print('🔐 Logging in as superuser...');
  await pb.collection('_superusers').authWithPassword(adminEmail, adminPassword);
  print('✅ Logged in! Token: ${pb.authStore.token}');

  final tempUsername = 'TempUser';
  final tempPassword = 'temppass';
  final tempEmail = 'temp@email.com';

  final body = <String, dynamic>{
      'username': tempUsername,
      'password': tempPassword,
      'passwordConfirm': tempPassword,
      'email': tempEmail,
    };

  try {
    final record = await pb.collection('users').create(body: body);

    print('✅ Temporary user created successfully!');
    print('Username: $tempUsername');
    print('Password: $tempPassword');
    print('Email: $tempEmail');
    print('Record ID: ${record.id}');
  } catch (e) {
    print('❌ Failed to create temporary user: $e');
  }
}
