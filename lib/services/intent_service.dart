import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class IntentService {
  static IntentService? _instance;

  IntentService._();

  static IntentService get instance {
    _instance ??= IntentService._();
    return _instance!;
  }

  /// Launch CliniqTV app by package name
  Future<bool> launchCliniqTv(String packageName) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: packageName,
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );

      // Check if the app is available
      final canResolve = await intent.canResolveActivity();
      if (canResolve != null && canResolve) {
        await intent.launch();
        return true;
      } else {
        print('CliniqTV app not found: $packageName');
        return false;
      }
    } catch (e) {
      print('Error launching CliniqTV: $e');
      return false;
    }
  }

  /// Launch any app by package name
  Future<bool> launchApp(String packageName) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: packageName,
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('Error launching app: $e');
      return false;
    }
  }
}
