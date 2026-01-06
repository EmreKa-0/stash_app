class UserSession {
  static bool _isLoggedIn = false;
  static String _userName = 'Guest User';
  static String _userEmail = 'guest@example.com';
  static String _userType = 'guest'; // 'visitor', 'employee', 'guest'

  static bool get isLoggedIn => _isLoggedIn;
  static String get userName => _userName;
  static String get userEmail => _userEmail;
  static String get userType => _userType;

  static void login({
    required String name,
    required String email,
    required String type,
  }) {
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;
    _userType = type;
  }

  static void logout() {
    _isLoggedIn = false;
    _userName = 'Guest User';
    _userEmail = 'guest@example.com';
    _userType = 'guest';
  }
}
