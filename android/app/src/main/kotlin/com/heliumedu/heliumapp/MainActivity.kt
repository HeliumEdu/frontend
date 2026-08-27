package com.heliumedu.heliumapp

import android.content.Context
import android.net.ConnectivityManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.heliumedu.heliumapp/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isTestFarmDevice" -> {
                    result.success(HeliumApplication.isTestFarmDevice)
                }
                "getSystemProxy" -> {
                    result.success(systemProxy())
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Manually configured Wi-Fi proxy, or null when none is set or it is PAC-based. */
    private fun systemProxy(): Map<String, Any>? {
        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return null
        val proxyInfo = connectivityManager.defaultProxy ?: return null
        val host = proxyInfo.host
        if (host.isNullOrEmpty() || proxyInfo.port <= 0) return null
        if (proxyInfo.pacFileUrl != Uri.EMPTY) return null
        return mapOf("host" to host, "port" to proxyInfo.port)
    }
}
