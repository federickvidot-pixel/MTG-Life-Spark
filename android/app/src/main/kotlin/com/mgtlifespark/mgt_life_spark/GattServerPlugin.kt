package com.mgtlifespark.mgt_life_spark

import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Native Android GATT server plugin for MGT Life Spark.
 *
 * Bridges Flutter's MethodChannel/EventChannel to Android BLE Peripheral APIs:
 *  - MethodChannel "mgt_life_spark/ble_host"  → startServer / stopServer / notifyClient
 *  - EventChannel  "mgt_life_spark/ble_host/events" → clientConnected / clientDisconnected / dataReceived
 */
class GattServerPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val bluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    private var gattServer: BluetoothGattServer? = null
    private var advertiseCallback: AdvertiseCallback? = null
    private var eventSink: EventChannel.EventSink? = null

    private val connectedDevices = mutableListOf<BluetoothDevice>()

    private var serviceUuid: UUID = UUID.randomUUID()
    private var txCharUuid: UUID = UUID.randomUUID()
    private var rxCharUuid: UUID = UUID.randomUUID()

    // CCCD descriptor UUID (standard BLE notification enable descriptor)
    private val cccdUuid = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

    // ── MethodChannel handler ─────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startServer" -> {
                val svc = call.argument<String>("serviceUuid")
                    ?: return result.error("INVALID_ARGS", "Missing serviceUuid", null)
                val tx = call.argument<String>("txCharUuid")
                    ?: return result.error("INVALID_ARGS", "Missing txCharUuid", null)
                val rx = call.argument<String>("rxCharUuid")
                    ?: return result.error("INVALID_ARGS", "Missing rxCharUuid", null)

                serviceUuid = UUID.fromString(svc)
                txCharUuid = UUID.fromString(tx)
                rxCharUuid = UUID.fromString(rx)

                startServer(result)
            }

            "stopServer" -> {
                stopServer()
                result.success(null)
            }

            "notifyClient" -> {
                val deviceId = call.argument<String>("deviceId")
                    ?: return result.error("INVALID_ARGS", "Missing deviceId", null)
                // Dart List<int> arrives as ArrayList<*>; Uint8List arrives as ByteArray
                val bytes: ByteArray = when (val raw = call.argument<Any>("data")) {
                    is ByteArray -> raw
                    is List<*> -> raw.map { (it as Number).toByte() }.toByteArray()
                    else -> return result.error("INVALID_ARGS", "Missing or invalid data", null)
                }
                notifyClient(deviceId, bytes, result)
            }

            else -> result.notImplemented()
        }
    }

    // ── Server lifecycle ──────────────────────────────────────────────────────

    private fun startServer(result: MethodChannel.Result) {
        try {
            val callback = buildGattCallback()
            gattServer = bluetoothManager.openGattServer(context, callback)

            // Build GATT service
            val service = BluetoothGattService(
                serviceUuid,
                BluetoothGattService.SERVICE_TYPE_PRIMARY
            )

            // TX characteristic — NOTIFY (host → clients)
            val txChar = BluetoothGattCharacteristic(
                txCharUuid,
                BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                BluetoothGattCharacteristic.PERMISSION_READ
            ).apply {
                addDescriptor(
                    BluetoothGattDescriptor(
                        cccdUuid,
                        BluetoothGattDescriptor.PERMISSION_READ or
                                BluetoothGattDescriptor.PERMISSION_WRITE
                    )
                )
            }

            // RX characteristic — WRITE (clients → host)
            val rxChar = BluetoothGattCharacteristic(
                rxCharUuid,
                BluetoothGattCharacteristic.PROPERTY_WRITE,
                BluetoothGattCharacteristic.PERMISSION_WRITE
            )

            service.addCharacteristic(txChar)
            service.addCharacteristic(rxChar)
            gattServer?.addService(service)

            // Start advertising
            val adapter = bluetoothManager.adapter
            val advertiser = adapter.bluetoothLeAdvertiser
                ?: return result.error(
                    "NOT_SUPPORTED",
                    "BLE advertising not supported on this device",
                    null
                )

            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setConnectable(true)
                .setTimeout(0)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                .build()

            val data = AdvertiseData.Builder()
                .setIncludeDeviceName(false)
                .addServiceUuid(ParcelUuid(serviceUuid))
                .build()

            val scanResponse = AdvertiseData.Builder()
                .setIncludeDeviceName(true)
                .build()

            advertiseCallback = object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                    mainHandler.post { result.success(null) }
                }

                override fun onStartFailure(errorCode: Int) {
                    mainHandler.post {
                        result.error(
                            "ADVERTISE_FAILED",
                            "Advertising failed. Error code: $errorCode",
                            null
                        )
                    }
                }
            }

            advertiser.startAdvertising(settings, data, scanResponse, advertiseCallback)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", "Missing BLE permission: ${e.message}", null)
        } catch (e: Exception) {
            result.error("START_FAILED", e.message, null)
        }
    }

    private fun stopServer() {
        try {
            val adapter = bluetoothManager.adapter
            advertiseCallback?.let {
                adapter.bluetoothLeAdvertiser?.stopAdvertising(it)
            }
            advertiseCallback = null
            gattServer?.close()
            gattServer = null
            connectedDevices.clear()
        } catch (_: Exception) { }
    }

    // ── Notify a connected client ─────────────────────────────────────────────

    private fun notifyClient(deviceId: String, data: ByteArray, result: MethodChannel.Result) {
        val device = connectedDevices.find { it.address == deviceId }
            ?: return result.error("DEVICE_NOT_FOUND", "No device: $deviceId", null)

        val txChar = gattServer
            ?.getService(serviceUuid)
            ?.getCharacteristic(txCharUuid)
            ?: return result.error("CHAR_NOT_FOUND", "TX characteristic unavailable", null)

        val notifyResult: Int = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // API 33+: pass value directly; returns GATT status code (0 = success)
            gattServer?.notifyCharacteristicChanged(device, txChar, false, data)
                ?: BluetoothGatt.GATT_FAILURE
        } else {
            // API <33: set value on characteristic then notify; returns Boolean
            @Suppress("DEPRECATION")
            txChar.value = data
            @Suppress("DEPRECATION")
            val ok = gattServer?.notifyCharacteristicChanged(device, txChar, false) ?: false
            if (ok) BluetoothGatt.GATT_SUCCESS else BluetoothGatt.GATT_FAILURE
        }

        if (notifyResult == BluetoothGatt.GATT_SUCCESS) result.success(null)
        else result.error("NOTIFY_FAILED", "Failed to notify $deviceId (status=$notifyResult)", null)
    }

    // ── GATT server callbacks ─────────────────────────────────────────────────

    private fun buildGattCallback() = object : BluetoothGattServerCallback() {

        override fun onConnectionStateChange(
            device: BluetoothDevice, status: Int, newState: Int
        ) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedDevices.add(device)
                    sendEvent(
                        mapOf("type" to "clientConnected", "deviceId" to device.address)
                    )
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    connectedDevices.remove(device)
                    sendEvent(
                        mapOf("type" to "clientDisconnected", "deviceId" to device.address)
                    )
                }
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            if (characteristic.uuid == rxCharUuid) {
                if (responseNeeded) {
                    gattServer?.sendResponse(
                        device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null
                    )
                }
                sendEvent(
                    mapOf(
                        "type" to "dataReceived",
                        "deviceId" to device.address,
                        "data" to value.map { it.toInt() and 0xFF }
                    )
                )
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            if (responseNeeded) {
                gattServer?.sendResponse(
                    device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null
                )
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            gattServer?.sendResponse(
                device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null
            )
        }
    }

    // ── EventChannel stream handler ───────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun sendEvent(data: Map<String, Any>) {
        mainHandler.post { eventSink?.success(data) }
    }
}
