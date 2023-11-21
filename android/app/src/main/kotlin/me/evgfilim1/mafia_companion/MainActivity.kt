package me.evgfilim1.mafia_companion

import android.content.Intent
import android.os.Build
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val updater = SelfUpdater(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("MainActivity", "configureFlutterEngine: $flutterEngine")
        PlatformMessenger(flutterEngine.dartExecutor.binaryMessenger).apply {
            registerMethodHandler("selfUpdate") { call, result ->
                val apkPath = call.argument<String>("path")
                if (apkPath == null) {
                    result.error("INVALID_ARGUMENT", "apkPath is null", null)
                    return@registerMethodHandler
                }
                updater.updateFromPath(apkPath)
                result.success(null)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            updater.registerSessionCallback(
                UpdateProgressReporter(flutterEngine.dartExecutor.binaryMessenger),
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        Log.d("MainActivity", "onNewIntent: $intent")
        super.onNewIntent(intent)
        when (intent.action) {
            SelfUpdater.PACKAGE_INSTALLED_ACTION -> {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
                    error("onNewIntent called with PACKAGE_INSTALLED_ACTION on API < 21")
                }
                updater.handleIntent(intent)
            }
        }

    }
}
