// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

package com.heliumedu.heliumapp

import android.util.Log
import io.flutter.app.FlutterApplication
import io.sentry.android.core.SentryAndroid

/**
 * Custom Application class that initializes Sentry BEFORE Flutter.
 *
 * Native crashes (SIGABRT, etc.) are captured by the NDK signal handler,
 * written to disk, and sent on the NEXT app launch. If we wait for
 * sentry_flutter to initialize Sentry from Dart, the cached crash envelopes
 * are sent before we can register our EventProcessor.
 *
 * By initializing Sentry here with our EventProcessor already configured,
 * we ensure test farm device crashes are filtered before being sent.
 *
 * IMPORTANT: This requires setting `autoInitializeNativeSdk = false` in
 * SentryFlutter.init() so it doesn't re-initialize the native SDK.
 */
class HeliumApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()

        // Initialize Sentry BEFORE Flutter starts, with our EventProcessor.
        // sentry_flutter will skip native init when autoInitializeNativeSdk=false.
        try {
            SentryAndroid.init(this) { options ->
                options.dsn = "https://d6522731f64a56983e3504ed78390601@o4510767194570752.ingest.us.sentry.io/4510767197519872"

                // Add our test farm filter BEFORE any events are processed
                options.addEventProcessor(TestFarmEventProcessor())

                // Performance monitoring (matches Dart config)
                options.tracesSampleRate = 0.1
                options.profilesSampleRate = 0.1

                // Enable native crash handling
                options.isEnableUncaughtExceptionHandler = true
                options.isAnrEnabled = true
            }
            Log.d(TAG, "Sentry initialized with TestFarmEventProcessor")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Sentry: ${e.message}")
        }
    }

    companion object {
        private const val TAG = "HeliumApplication"
    }
}
