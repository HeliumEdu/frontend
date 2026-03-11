// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

package com.heliumedu.heliumapp

import android.util.Log
import io.sentry.EventProcessor
import io.sentry.Hint
import io.sentry.SentryEvent

/**
 * Filters out crash reports from Google Play's pre-launch test farm.
 *
 * The test farm uses real devices but with virtualized/throttled hardware.
 * We detect these by checking for flagship devices reporting impossible specs:
 *
 * OnePlus 8 Pro (IN2025):
 *   Real specs: 8 cores, 8-12 GB RAM
 *   Test farm:  2 cores, ~4 GB RAM
 *   https://www.oneplus.com/us/8-pro/specs
 *
 * Note: Pixel 4a and other test farm devices are already filtered by the
 * Dart-level _isEmulatorOrTestDevice check (they have "-userdebug" in OS build).
 * This native filter catches devices that pass through with clean OS builds.
 */
class TestFarmEventProcessor : EventProcessor {

    override fun process(event: SentryEvent, hint: Hint): SentryEvent? {
        val shouldFilter = isTestFarmDevice(event)
        if (shouldFilter) {
            Log.i(TAG, "Filtering test farm event")
            return null
        }
        return event
    }

    private fun isTestFarmDevice(event: SentryEvent): Boolean {
        val device = event.contexts.device
        if (device == null) {
            Log.d(TAG, "Device context is null")
            return false
        }

        val model = device.model
        val processorCount = device.processorCount
        val memorySize = device.memorySize

        Log.d(TAG, "Event device: model=$model, cores=$processorCount, ram=$memorySize")

        if (model == null || processorCount == null || memorySize == null) {
            Log.d(TAG, "Missing device fields")
            return false
        }

        if (model == ONEPLUS_8_PRO_MODEL_ID || model == ONEPLUS_8_PRO_MODEL_NAME) {
            if (processorCount < ONEPLUS_8_PRO_MIN_CORES ||
                memorySize < ONEPLUS_8_PRO_MIN_RAM_BYTES) {
                Log.i(TAG, "Detected test farm OnePlus8Pro: cores=$processorCount, ram=$memorySize")
                return true
            }
        }

        return false
    }

    companion object {
        private const val TAG = "TestFarmEventProcessor"
        // OnePlus 8 Pro real specs
        // Model can be reported as "IN2025" (hardware ID) or "OnePlus8Pro" (marketing name)
        private const val ONEPLUS_8_PRO_MODEL_ID = "IN2025"
        private const val ONEPLUS_8_PRO_MODEL_NAME = "OnePlus8Pro"
        private const val ONEPLUS_8_PRO_MIN_CORES = 8
        private const val ONEPLUS_8_PRO_MIN_RAM_BYTES = 7L * 1024 * 1024 * 1024 // 7 GB
    }
}
