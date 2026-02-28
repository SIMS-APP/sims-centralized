import 'package:flutter/services.dart';
import '../utils/constants.dart';

class PipService {
  static const MethodChannel _channel =
      MethodChannel(AppConstants.pipChannel);

  static PipService? _instance;

  PipService._();

  static PipService get instance {
    _instance ??= PipService._();
    return _instance!;
  }

  /// Enter Picture-in-Picture mode
  Future<bool> enterPip() async {
    try {
      final result = await _channel.invokeMethod<bool>('enterPip');
      return result ?? false;
    } on PlatformException catch (e) {
      print('PIP Error: ${e.message}');
      return false;
    }
  }

  /// Check if PIP is supported on this device
  Future<bool> isPipSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isPipSupported');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if currently in PIP mode
  Future<bool> isPipActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isPipActive');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
