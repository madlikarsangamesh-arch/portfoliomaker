import 'package:appwrite/appwrite.dart';

class AppwriteService {
  AppwriteService._();

  static final AppwriteService instance = AppwriteService._();

  static const String _endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String _projectId = '6aa3f38f002db3cd2655';

  late final Client _client;

  Client get client => _client;

  void initialize() {
    _client = Client()
      ..setEndpoint(_endpoint)
      ..setProject(_projectId)
      ..setSelfSigned(status: false);
  }

  Future<bool> healthCheck() async {
    try {
      final account = Account(_client);
      await account.get();
      return true;
    } catch (_) {
      return false;
    }
  }
}
