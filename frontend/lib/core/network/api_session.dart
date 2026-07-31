class ApiSession {
  ApiSession._();

  static final ApiSession instance = ApiSession._();

  String? accessToken;
  String? realtimeToken;
  String? userId;
  String? communityId;
  String? userRole;

  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  void clear() {
    accessToken = null;
    realtimeToken = null;
    userId = null;
    communityId = null;
    userRole = null;
  }
}
