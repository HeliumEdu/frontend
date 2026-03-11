// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

package com.heliumedu.heliumapp

import android.util.Log
import io.flutter.app.FlutterApplication
import io.sentry.Sentry
import io.sentry.SentryOptions

/**
 * Custom Application class that registers Sentry EventProcessors early.
 *
 * Native crashes (SIGABRT, etc.) are captured by the NDK signal handler,
 * written to disk, and sent on the NEXT app launch. By the time our Dart
 * code runs, those cached envelopes may already be sent.
 *
 * This class uses Sentry's beforeSendCallback configuration to filter
 * test farm devices before any events are sent.
 */
class HeliumApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()

        // Register our EventProcessor with Sentry.
        // This runs after Sentry auto-init (via ContentProvider) but before
        // Flutter/Dart code, ensuring native crash envelopes are filtered.
        try {
            val hub = Sentry.getCurrentHub()
            val options = hub.options
            if (options != null) {
                options.addEventProcessor(TestFarmEventProcessor())
                Log.d(TAG, "Registered TestFarmEventProcessor")
            } else {
                Log.w(TAG, "Sentry options is null - EventProcessor not registered")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register EventProcessor: ${e.message}")
        }
    }

    companion object {
        private const val TAG = "HeliumApplication"
    }
}
