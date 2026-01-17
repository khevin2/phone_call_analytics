package com.callsense.app

import android.content.ContentResolver
import android.os.Build
import android.provider.CallLog
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "callsense/call_log"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCallLogs" -> {
                        val fromMillis = call.argument<Long>("fromMillis") ?: 0L
                        val toMillis = call.argument<Long>("toMillis") ?: System.currentTimeMillis()
                        try {
                            val logs = queryCallLogs(contentResolver, fromMillis, toMillis)
                            result.success(logs)
                        } catch (e: Exception) {
                            result.error("CALL_LOG_ERROR", e.message, null)
                        }
                    }
                    "getSubscriptions" -> {
                        try {
                            result.success(getSubscriptionDetails())
                        } catch (e: Exception) {
                            result.error("SUBSCRIPTION_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun queryCallLogs(
        resolver: ContentResolver,
        fromMillis: Long,
        toMillis: Long,
    ): List<Map<String, Any?>> {
        val projection = mutableListOf(
            CallLog.Calls._ID,
            CallLog.Calls.NUMBER,
            CallLog.Calls.CACHED_NAME,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            projection.add(CallLog.Calls.PHONE_ACCOUNT_ID)
            projection.add(CallLog.Calls.PHONE_ACCOUNT_COMPONENT_NAME)
        }

        val selection = "${CallLog.Calls.DATE} >= ? AND ${CallLog.Calls.DATE} <= ?"
        val selectionArgs = arrayOf(fromMillis.toString(), toMillis.toString())

        val results = mutableListOf<Map<String, Any?>>()
        resolver.query(
            CallLog.Calls.CONTENT_URI,
            projection.toTypedArray(),
            selection,
            selectionArgs,
            "${CallLog.Calls.DATE} DESC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(CallLog.Calls._ID)
            val numberIndex = cursor.getColumnIndex(CallLog.Calls.NUMBER)
            val nameIndex = cursor.getColumnIndex(CallLog.Calls.CACHED_NAME)
            val typeIndex = cursor.getColumnIndex(CallLog.Calls.TYPE)
            val dateIndex = cursor.getColumnIndex(CallLog.Calls.DATE)
            val durationIndex = cursor.getColumnIndex(CallLog.Calls.DURATION)
            val phoneAccountIdIndex = cursor.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID)
            val phoneAccountComponentIndex =
                cursor.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_COMPONENT_NAME)

            while (cursor.moveToNext()) {
                val callId = cursor.getLong(idIndex)
                val number = cursor.getString(numberIndex)
                val name = if (nameIndex != -1) cursor.getString(nameIndex) else null
                val type = cursor.getInt(typeIndex)
                val timestamp = cursor.getLong(dateIndex)
                val duration = cursor.getLong(durationIndex)
                val phoneAccountId = if (phoneAccountIdIndex != -1) {
                    cursor.getString(phoneAccountIdIndex)
                } else null
                val phoneAccountComponent = if (phoneAccountComponentIndex != -1) {
                    cursor.getString(phoneAccountComponentIndex)
                } else null

                val simSlot = resolveSimSlot(phoneAccountComponent, phoneAccountId)

                results.add(
                    mapOf(
                        "callId" to callId,
                        "number" to (number ?: "Unknown"),
                        "name" to name,
                        "type" to mapCallType(type),
                        "timestamp" to timestamp,
                        "durationSec" to duration,
                        "phoneAccountId" to phoneAccountId,
                        "phoneAccountComponentName" to phoneAccountComponent,
                        "subscriptionId" to simSlot.subscriptionId,
                        "simSlot" to simSlot.simSlotIndex,
                    )
                )
            }
        }
        return results
    }

    private fun mapCallType(type: Int): Int {
        return when (type) {
            CallLog.Calls.INCOMING_TYPE -> 0
            CallLog.Calls.OUTGOING_TYPE -> 1
            CallLog.Calls.MISSED_TYPE -> 2
            CallLog.Calls.REJECTED_TYPE -> 3
            else -> 4
        }
    }

    private data class SimSlotResult(val subscriptionId: Int?, val simSlotIndex: Int)

    private fun resolveSimSlot(
        phoneAccountComponent: String?,
        phoneAccountId: String?,
    ): SimSlotResult {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return SimSlotResult(null, 0)
        }
        val telecomManager = getSystemService(TELECOM_SERVICE) as TelecomManager
        val accounts = telecomManager.callCapablePhoneAccounts
        val handle = accounts.firstOrNull { account: PhoneAccountHandle ->
            account.id == phoneAccountId &&
                account.componentName.flattenToString() == phoneAccountComponent
        }
        if (handle != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val phoneAccount = telecomManager.getPhoneAccount(handle)
            val extras = phoneAccount?.extras
            val subId = extras?.getInt(TelecomManager.EXTRA_SUBSCRIPTION_ID, -1) ?: -1
            if (subId != -1) {
                val simSlotIndex =
                    SubscriptionManager.getSlotIndex(subId).takeIf { it >= 0 } ?: 0
                return SimSlotResult(subId, simSlotIndex + 1)
            }
        }
        return SimSlotResult(null, 0)
    }

    private fun getSubscriptionDetails(): List<Map<String, Any?>> {
        val subscriptionManager =
            getSystemService(TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
        val subscriptions = subscriptionManager.activeSubscriptionInfoList ?: emptyList()
        return subscriptions.map { info: SubscriptionInfo ->
            mapOf(
                "subscriptionId" to info.subscriptionId,
                "simSlotIndex" to info.simSlotIndex + 1,
                "displayName" to info.displayName.toString(),
                "carrierName" to info.carrierName.toString(),
                "number" to info.number,
            )
        }
    }
}
