class ApiSession {
  ApiSession._();

  static final ApiSession instance = ApiSession._();

  String? accessToken;

  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  void clear() {
    accessToken = null;
  }
}
