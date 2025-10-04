import 'package:flutter/foundation.dart';
import 'package:deck_builder/data/util/api.dart';

class UserProvider with ChangeNotifier {
  final APIRunner apiRunner = APIRunner();

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String username, String password) async {
    final userData = await apiRunner.login(username, password);
    if (userData != null) {
      _currentUser = userData;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signup(String username, String password, String email) async {
    final userData = await apiRunner.signup(username, password, email);
    if (userData != null) {
      _currentUser = userData;
      notifyListeners();
      return true;
    }
    return false;
  }

  void setUser(Map<String, dynamic> userData) {
    _currentUser = userData;
    notifyListeners();
  }

  
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
