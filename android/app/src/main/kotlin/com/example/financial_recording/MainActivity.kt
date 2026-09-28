package com.example.financial_recording

import android.content.Intent
import android.nfc.NfcAdapter
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Wallet was picked from Android's NFC "Pilih tindakan" sheet: remember it
 * so the Flutter side opens Cek Saldo Kartu (see LaunchIntents in Dart).
 * Also reports which store installed the app (see distribution.dart).
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingNfc = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null && isNfc(intent)) pendingNfc = true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "wallet/launch").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeNfcLaunch" -> {
                        result.success(pendingNfc)
                        pendingNfc = false
                    }
                    // Which store installed us: Play hides the donation page.
                    "installer" -> result.success(installerPackage())
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (!isNfc(intent)) return
        val ch = channel
        if (ch != null) ch.invokeMethod("nfcTapped", null) else pendingNfc = true
    }

    private fun installerPackage(): String? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            packageManager.getInstallSourceInfo(packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstallerPackageName(packageName)
        }
    } catch (e: Exception) {
        null
    }

    private fun isNfc(intent: Intent?): Boolean = when (intent?.action) {
        NfcAdapter.ACTION_TECH_DISCOVERED, NfcAdapter.ACTION_TAG_DISCOVERED, NfcAdapter.ACTION_NDEF_DISCOVERED -> true
        else -> false
    }
}
