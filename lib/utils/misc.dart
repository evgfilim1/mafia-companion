import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

import "log.dart";

const kIsDev = kDebugMode || appFlavor == "dev";

const _enableUpdaterEnv = String.fromEnvironment("ENABLE_UPDATER");
const _enableDebugMenuEnv = String.fromEnvironment("ENABLE_DEBUG_MENU");
const _enableShowIdsEnv = String.fromEnvironment("ENABLE_SHOW_IDS");

const kEnableUpdater = _enableUpdaterEnv != "" && _enableUpdaterEnv != "0";
const kEnableDebugMenu = _enableDebugMenuEnv != "" && _enableDebugMenuEnv != "0";
const kEnableShowIds = _enableShowIdsEnv != "" && _enableShowIdsEnv != "0";

void logFlags() {
  final log = Logger("flags");
  if (kIsDev) {
    log.debug("Running in dev mode");
  }
  if (kEnableUpdater) {
    log.warning("Updater enabled via ENABLE_UPDATER");
  }
  if (kEnableDebugMenu) {
    log.warning("Debug menu enabled via ENABLE_DEBUG_MENU");
  }
  if (kEnableShowIds) {
    log.warning("Show IDs enabled via ENABLE_SHOW_IDS");
  }
}
