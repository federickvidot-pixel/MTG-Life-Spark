package com.mgtlifespark.mgt_life_spark

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val plugin = GattServerPlugin(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mgt_life_spark/ble_host"
        ).setMethodCallHandler(plugin)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mgt_life_spark/ble_host/events"
        ).setStreamHandler(plugin)
    }
}
