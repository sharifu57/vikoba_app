package com.example.vikoba_app

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var smsChannel: MethodChannel
    private var smsReceiver: BroadcastReceiver? = null
    private var generation = 0
    private var consentRequest = -1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        smsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vikoba/otp_sms")
        smsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> startListening(result)
                "stop" -> { stopListening(); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun startListening(result: MethodChannel.Result) {
        stopListening()
        val session = generation
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (session != generation || intent.action != SmsRetriever.SMS_RETRIEVED_ACTION) return
                val status = intent.getParcelableExtra<Status>(SmsRetriever.EXTRA_STATUS)
                if (status?.statusCode == CommonStatusCodes.SUCCESS) {
                    val consent = intent.getParcelableExtra<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT) ?: return
                    consentRequest = 2000 + session % 10000
                    try { startActivityForResult(consent, consentRequest) }
                    catch (_: Exception) { stopListening() }
                } else if (status?.statusCode == CommonStatusCodes.TIMEOUT) {
                    stopListening()
                }
            }
        }
        try {
            val filter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(receiver, filter, SmsRetriever.SEND_PERMISSION, null, Context.RECEIVER_EXPORTED)
            } else {
                registerReceiver(receiver, filter, SmsRetriever.SEND_PERMISSION, null)
            }
            smsReceiver = receiver
            SmsRetriever.getClient(this).startSmsUserConsent(null)
                .addOnSuccessListener { result.success(session == generation) }
                .addOnFailureListener {
                    if (session == generation) stopListening()
                    result.success(false)
                }
        } catch (_: Exception) {
            stopListening()
            result.success(false)
        }
    }

    @Deprecated("Used by the SMS User Consent API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != consentRequest || smsReceiver == null) return
        val message = if (resultCode == Activity.RESULT_OK)
            data?.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE) else null
        stopListening()
        if (message != null) smsChannel.invokeMethod("sms", message)
    }

    private fun stopListening() {
        generation++
        consentRequest = -1
        smsReceiver?.let { unregisterReceiver(it) }
        smsReceiver = null
    }

    override fun onDestroy() {
        stopListening()
        if (::smsChannel.isInitialized) smsChannel.setMethodCallHandler(null)
        super.onDestroy()
    }
}
