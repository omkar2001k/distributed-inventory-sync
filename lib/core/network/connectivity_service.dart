import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service monitoring network hardware connection state.
class ConnectivityService {
  final Connectivity _connectivity;
  final _stateController = StreamController<List<ConnectivityResult>>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _stateController.add(results);
    });
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged => _stateController.stream;

  Future<bool> hasNetworkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isAnyConnected(results);
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasWifiConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi);
    } catch (_) {
      return false;
    }
  }

  bool _isAnyConnected(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}
