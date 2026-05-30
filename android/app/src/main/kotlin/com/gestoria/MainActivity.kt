package com.gestoria

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "gestoria/pdf_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "compartirPdf") {
                    val bytes = call.argument<ByteArray>("bytes")
                    val nombre = call.argument<String>("nombre") ?: "reporte.pdf"

                    if (bytes == null) {
                        result.error("ERROR", "Sin datos PDF", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val uri = guardarEnDescargas(bytes, nombre)
                        compartir(uri)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun guardarEnDescargas(bytes: ByteArray, nombre: String): Uri {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ — usar MediaStore (no necesita permisos)
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, nombre)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val collection = MediaStore.Downloads.getContentUri(
                MediaStore.VOLUME_EXTERNAL_PRIMARY
            )
            val itemUri = contentResolver.insert(collection, values)!!
            contentResolver.openOutputStream(itemUri)?.use { it.write(bytes) }
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            contentResolver.update(itemUri, values, null, null)
            itemUri
        } else {
            // Android 9 y anterior — archivo directo en Descargas
            val dir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            dir.mkdirs()
            val file = File(dir, nombre)
            file.writeBytes(bytes)
            Uri.fromFile(file)
        }
    }

    private fun compartir(uri: Uri) {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, "Compartir reporte"))
    }
}
