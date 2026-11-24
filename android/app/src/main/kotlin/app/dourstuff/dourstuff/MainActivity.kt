package app.dourstuff.dourstuff

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val records = CredentialRecords(applicationContext)
        MethodChannel(messenger, "app.dourstuff/credential-record/v1",
            io.flutter.plugin.common.StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()).setMethodCallHandler { call, result ->
            if (call.method != "seal" && call.method != "open") {
                result.notImplemented()
            } else {
                try {
                    val context = requireNotNull(call.argument<ByteArray>("context"))
                    val data = requireNotNull(call.argument<ByteArray>("data"))
                    result.success(records.transform(call.method == "seal", context, data))
                } catch (_: Exception) {
                    result.error("unavailable", null, null)
                }
            }
        }
    }
}
