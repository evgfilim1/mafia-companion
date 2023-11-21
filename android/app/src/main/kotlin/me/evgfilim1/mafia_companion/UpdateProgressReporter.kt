package me.evgfilim1.mafia_companion

import android.content.pm.PackageInstaller
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class UpdateProgressReporter(binaryMessenger: BinaryMessenger) : PackageInstaller.SessionCallback() {
    init {
        EventChannel(binaryMessenger, CHANNEL_NAME).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events == null) {
                        error("event sink is null")
                    }
                    this@UpdateProgressReporter.events = events
                }

                override fun onCancel(arguments: Any?) {
                    events = null
                }
            })
        }
    }

    private var events: EventChannel.EventSink? = null

    var filterSessionId: Int? = null

    override fun onCreated(sessionId: Int) { /* noop */ }

    override fun onBadgingChanged(sessionId: Int) { /* noop */ }

    override fun onActiveChanged(sessionId: Int, active: Boolean) { /* noop */ }

    override fun onProgressChanged(sessionId: Int, progress: Float) {
        if (sessionId != filterSessionId) {
            Log.d("UpdateProgressReporter", "onProgressChanged: filtered out $sessionId")
            return
        }
        events?.success(progress)
    }

    override fun onFinished(sessionId: Int, success: Boolean) {
        if (sessionId != filterSessionId) {
            Log.d("UpdateProgressReporter", "onFinished: filtered out $sessionId")
            return
        }
        if (!success) {
            events?.error("UPDATE_SESSION_FAILED", "Session finished with error", null)
        }
        events?.endOfStream()
    }

    companion object {
        private const val CHANNEL_NAME = "me.evgfilim1.mafia_companion/installProgress"
    }
}
