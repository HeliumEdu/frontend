package com.heliumedu.heliumapp

import android.net.ConnectivityManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val NATIVE_CHANNEL_NAME = "com.heliumedu.heliumapp/native"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "isTestFarmDevice" -> result.success(HeliumApplication.isTestFarmDevice)
                "getSystemProxy" -> result.success(systemProxy())
                else -> result.notImplemented()
            }
        }
    }

    private fun systemProxy(): Map<String, Any>? {
        val proxyInfo = getSystemService(ConnectivityManager::class.java).defaultProxy ?: return null
        val host = proxyInfo.host
        if (host.isNullOrEmpty() || proxyInfo.port <= 0) return null
        if (proxyInfo.pacFileUrl != Uri.EMPTY) return null
        return mapOf("host" to host, "port" to proxyInfo.port)
    }
}
