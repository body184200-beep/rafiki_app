import 'package:upgrader/upgrader.dart';

/// Store-update prompt. On iOS this looks the app up by its bundle id.
class AppUpgraderService {
  static final Upgrader instance = Upgrader(
    durationUntilAlertAgain: const Duration(days: 3),
  );
}
