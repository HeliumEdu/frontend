// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

package com.heliumedu.heliumapp

import android.app.ActivityManager
import android.app.Application
import android.content.Context
import android.os.Build

/**
 * Custom Application class that detects Google Play pre-launch test farm devices.
 *
 * Native crashes bypass Dart-level Sentry filters (sent via captureEnvelope),
 * so we detect test farm devices early and expose a flag to Dart. When Dart
 * sees the flag, it skips Sentry initialization entirely.
 */
class HeliumApplication : Application() {

    companion object {
        /**
         * True if running on a Google Play pre-launch test farm device.
         * Checked by Dart before initializing Sentry.
         */
        @JvmStatic
        var isTestFarmDevice: Boolean = false
            private set
    }

    override fun onCreate() {
        super.onCreate()
        isTestFarmDevice = detectTestFarmDevice()
    }

    /**
     * Detect Google Play pre-launch test farm devices.
     *
     * Test farm devices are identified by:
     * 1. OS build signatures (test-keys, sdk_phone, userdebug, etc.)
     * 2. Flagship devices with impossible specs (virtualized/throttled hardware)
     */
    private fun detectTestFarmDevice(): Boolean {
        // Check OS build for test/emulator signatures
        val osBuild = Build.DISPLAY?.lowercase() ?: ""
        if (osBuild.contains("sdk_phone") ||
            osBuild.contains("sdk_gphone") ||
            osBuild.contains("test-keys") ||
            osBuild.contains("dev-keys") ||
            osBuild.contains("-userdebug")) {
            return true
        }

        // Check for flagship devices with impossible specs
        val model = Build.MODEL ?: return false
        val processorCount = Runtime.getRuntime().availableProcessors()
        val memoryBytes = getDeviceMemoryBytes()

        // OnePlus 8 Pro: real has 8 cores, 8-12 GB RAM
        // Test farm version: 2 cores, ~4 GB RAM
        if (model == "IN2025" || model == "OnePlus8Pro") {
            if (processorCount < 8 || memoryBytes < 7L * 1024 * 1024 * 1024) {
                return true
            }
        }

        // Pixel 6 Pro: real has 8 cores, 12 GB RAM
        // Test farm version: 4 cores, ~3 GB RAM
        if (model == "Pixel 6 Pro") {
            if (processorCount < 8 || memoryBytes < 10L * 1024 * 1024 * 1024) {
                return true
            }
        }

        return false
    }

    private fun getDeviceMemoryBytes(): Long {
        return try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memInfo)
            memInfo.totalMem
        } catch (e: Exception) {
            0L
        }
    }
}
