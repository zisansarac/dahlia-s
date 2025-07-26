class ApiConstants {
  // static const String baseUrl = "http://10.0.2.2:3000"; // Android emulator için
  static const String baseUrl = "http://10.0.2.2:3000"; // Web için

  static const String login = "$baseUrl/api/auth/login";
  static const String register = "$baseUrl/api/auth/register";
  static const String orders = "$baseUrl/api/orders";
  static const String forgotPassword = "$baseUrl/api/auth/forgot-password";
  static const String resetPassword = "$baseUrl/api/auth/reset-password";
}
