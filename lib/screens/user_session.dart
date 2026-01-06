class UserSession {
  static String userName = "Guest";
  static String userEmail = "";
  static String userType = "visitor"; // 'employee' veya 'visitor'
  static bool isLoggedIn = false;

  static void login({required String name, required String email, required String type}) {
    userName = name;
    userEmail = email;
    userType = type;
    isLoggedIn = true;
  }

  static void logout() {
    userName = "Guest";
    userEmail = "";
    userType = "visitor";
    isLoggedIn = false;
  }
}