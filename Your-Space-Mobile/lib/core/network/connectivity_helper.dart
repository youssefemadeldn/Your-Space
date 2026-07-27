import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ConnectivityHelper {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  Stream<bool> get connectivityStream =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
