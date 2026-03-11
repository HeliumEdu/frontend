// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

package com.heliumedu.heliumapp

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

    companion object {
        // OnePlus 8 Pro real specs
        // Model can be reported as "IN2025" (hardware ID) or "OnePlus8Pro" (marketing name)
        private const val ONEPLUS_8_PRO_MODEL_ID = "IN2025"
        private const val ONEPLUS_8_PRO_MODEL_NAME = "OnePlus8Pro"
        private const val ONEPLUS_8_PRO_MIN_CORES = 8
        private const val ONEPLUS_8_PRO_MIN_RAM_BYTES = 7L * 1024 * 1024 * 1024 // 7 GB
    }

    override fun process(event: SentryEvent, hint: Hint): SentryEvent? {
        return if (isTestFarmDevice(event)) null else event
    }

    private fun isTestFarmDevice(event: SentryEvent): Boolean {
        val device = event.contexts.device ?: return false

        val model = device.model ?: return false
        val processorCount = device.processorCount ?: return false
        val memorySize = device.memorySize ?: return false

        if (model == ONEPLUS_8_PRO_MODEL_ID || model == ONEPLUS_8_PRO_MODEL_NAME) {
            if (processorCount < ONEPLUS_8_PRO_MIN_CORES ||
                memorySize < ONEPLUS_8_PRO_MIN_RAM_BYTES) {
                return true
            }
        }

        return false
    }
}
