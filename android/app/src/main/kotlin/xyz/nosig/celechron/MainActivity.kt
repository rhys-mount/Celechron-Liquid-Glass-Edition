package xyz.nosig.celechron

import android.os.Bundle
import androidx.glance.appwidget.updateAll
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = 0
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "top.celechron.celechron/ecardWidget").setMethodCallHandler {
                call, result ->
            val refresh = when (call.method) {
                "update", "logout" -> true
                "setAppearance" -> {
                    val mode = call.arguments as? String
                    if (mode == null || mode !in listOf("system", "light", "dark")) {
                        result.error("invalid_appearance", "Unknown widget appearance", null)
                        return@setMethodCallHandler
                    }
                    ECardWidget.setBrightness(this, mode)
                }
                else -> {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
            }
            if (refresh) {
                CoroutineScope(Dispatchers.Main).launch {
                    ECardWidget().updateAll(this@MainActivity)
                }
            }
            result.success(null)
        }
    }
}
