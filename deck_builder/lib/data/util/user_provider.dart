import 'package:flutter/foundation.dart';
import '../model/user.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateEmail(String email) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        username: _currentUser!.username,
        email: email,
      );
      notifyListeners();
    }
  }

  void updateUsername(String username) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        username: username,
        email: _currentUser!.email,
      );
      notifyListeners();
    }
  }
}
