// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

package com.heliumedu.heliumapp

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.app.FlutterApplication

/**
 * Custom Application class that detects Google Play pre-launch test farm devices.
 *
 * Native crashes bypass Dart-level Sentry filters (sent via captureEnvelope),
 * so we detect test farm devices early and expose a flag to Dart. When Dart
 * sees the flag, it skips Sentry initialization entirely.
 */
class HeliumApplication : FlutterApplication() {

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
     * Test farm devices are real hardware with virtualized/throttled specs.
     * We detect them by checking for flagship devices with impossible specs:
     *
     * OnePlus 8 Pro (IN2025):
     *   Real specs: 8 cores, 8-12 GB RAM
     *   Test farm:  2 cores, ~4 GB RAM
     */
    private fun detectTestFarmDevice(): Boolean {
        val model = Build.MODEL ?: return false

        // OnePlus 8 Pro can report as "IN2025" (hardware ID) or "OnePlus8Pro"
        if (model == "IN2025" || model == "OnePlus8Pro") {
            val processorCount = Runtime.getRuntime().availableProcessors()
            val memoryBytes = getDeviceMemoryBytes()

            // Real OnePlus 8 Pro: 8 cores, 8-12 GB RAM
            // Test farm version: 2 cores, ~4 GB RAM
            if (processorCount < 8 || memoryBytes < 7L * 1024 * 1024 * 1024) {
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
