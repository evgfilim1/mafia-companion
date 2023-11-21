package me.evgfilim1.mafia_companion

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

typealias MethodHandler = (call: MethodCall, result: MethodChannel.Result) -> Unit

class PlatformMessenger(binaryMessenger: BinaryMessenger) {
    init {
        MethodChannel(binaryMessenger, CHANNEL_NAME).apply {
            setMethodCallHandler(::channelMethodCallHandler)
        }
    }

    private val methodHandlers = mutableMapOf<String, MethodHandler>()

    fun registerMethodHandler(method: String, handler: MethodHandler) {
        methodHandlers[method] = handler
    }

    private fun channelMethodCallHandler(call: MethodCall, result: MethodChannel.Result) {
        val handler = methodHandlers[call.method]
        if (handler == null) {
            result.notImplemented()
            return
        }
        try {
            handler(call, result)
        } catch (e: Exception) {
            result.error("NATIVE_EXCEPTION", e.message, e.stackTraceToString())
        }
    }

    companion object {
        private const val CHANNEL_NAME = "me.evgfilim1.mafia_companion/methods"
    }
}
