package com.heliumedu.heliumapp

import android.app.ActivityManager
import android.app.Application
import android.os.Build

/**
 * Flags Google Play pre-launch test devices and emulators before Dart starts, so Dart can skip initializing Sentry.
 * Native crash reports are sent by the native SDK and never pass through Dart-level filters.
 */
class HeliumApplication : Application() {

    companion object {
        private const val BYTES_PER_GIGABYTE = 1024L * 1024 * 1024

        var isTestFarmDevice: Boolean = false
            private set
    }

    override fun onCreate() {
        super.onCreate()
        isTestFarmDevice = isTestBuild() || isUnderpoweredFlagship()
    }

    private fun isTestBuild(): Boolean {
        val osBuild = Build.DISPLAY.lowercase()
        val fingerprint = Build.FINGERPRINT.lowercase()

        return osBuild.contains("sdk_phone") ||
            osBuild.contains("sdk_gphone") ||
            osBuild.contains("test-keys") ||
            osBuild.contains("dev-keys") ||
            osBuild.contains("-userdebug") ||
            fingerprint.contains("sdk_gphone") ||
            fingerprint.contains("emulator") ||
            fingerprint.contains("test-keys")
    }

    private fun isUnderpoweredFlagship(): Boolean {
        val processorCount = Runtime.getRuntime().availableProcessors()
        val memoryBytes = deviceMemoryBytes()

        return when (Build.MODEL) {
            "IN2025", "OnePlus8Pro" -> processorCount < 8 || memoryBytes < 7 * BYTES_PER_GIGABYTE
            "Pixel 6 Pro" -> processorCount < 8 || memoryBytes < 10 * BYTES_PER_GIGABYTE
            else -> false
        }
    }

    private fun deviceMemoryBytes(): Long {
        val memoryInfo = ActivityManager.MemoryInfo()
        getSystemService(ActivityManager::class.java).getMemoryInfo(memoryInfo)
        return memoryInfo.totalMem
    }
}
