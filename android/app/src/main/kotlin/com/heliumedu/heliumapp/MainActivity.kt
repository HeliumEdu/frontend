// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

package com.heliumedu.heliumapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.sentry.Sentry

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.heliumedu.heliumapp/sentry"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "registerTestFarmFilter" -> {
                    registerTestFarmEventProcessor()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun registerTestFarmEventProcessor() {
        val options = Sentry.getCurrentHub().options
        options.addEventProcessor(TestFarmEventProcessor())
    }
}
