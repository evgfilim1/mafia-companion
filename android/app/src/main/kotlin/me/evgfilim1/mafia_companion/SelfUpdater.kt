package me.evgfilim1.mafia_companion

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.Log
import java.io.File

class SelfUpdater(private val context: Context) {
    private var reporter: UpdateProgressReporter? = null

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun registerSessionCallback(sessionCallback: UpdateProgressReporter) {
        context.packageManager.packageInstaller.registerSessionCallback(sessionCallback)
        reporter = sessionCallback
    }

    fun updateFromPath(path: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !context.packageManager.canRequestPackageInstalls()) {
            error("Cannot request package installs, check app permissions")
        }
        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP -> doUpdateLollipop(path)
            else -> doUpdateLegacy(path)
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun doUpdateLollipop(path: String) {
        val file = File(path)
        if (!file.isFile) {
            error("File does not exist or is not a regular file: $path")
        }
        val sizeBytes = file.length()
        val session = context.packageManager.packageInstaller.let {
            val params = PackageInstaller.SessionParams(
                PackageInstaller.SessionParams.MODE_FULL_INSTALL,
            ).apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    setInstallReason(PackageManager.INSTALL_REASON_USER)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    // Next line has lint error, but it compiles and works fine
                    setPackageSource(PackageInstaller.PACKAGE_SOURCE_DOWNLOADED_FILE)
                }
                setSize(sizeBytes)
            }
            it.openSession(it.createSession(params).also { id -> reporter?.filterSessionId = id })
        }
        session.openWrite("update", 0, sizeBytes).use { out ->
            file.inputStream().use { input ->
                input.copyTo(out)
                session.fsync(out)
            }
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0,
            Intent(context, context.javaClass).apply {
                action = PACKAGE_INSTALLED_ACTION
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            },
            PendingIntent.FLAG_MUTABLE,
        )
        session.commit(pendingIntent.intentSender)
    }

    private fun doUpdateLegacy(path: String) {
        Intent(Intent.ACTION_VIEW).apply {
            data = Uri.fromFile(File(path))
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }.let(context::startActivity)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun handleIntent(intent: Intent) {
        if (intent.action != PACKAGE_INSTALLED_ACTION) {
            error("Unexpected intent action: ${intent.action}")
        }
        val extras = intent.extras ?: error("Intent has no extras")
        val status = extras.getInt(PackageInstaller.EXTRA_STATUS)
        val message = extras.getString(PackageInstaller.EXTRA_STATUS_MESSAGE)
        Log.d("SelfUpdater", "handleIntent: status=$status, message=$message")
        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                @SuppressLint("UnsafeIntentLaunch") // I'm checking the package and action below
                val installIntent = extras.getParcelable<Intent>(Intent.EXTRA_INTENT)!!
                if (installIntent.`package` !in KNOWN_INSTALLERS) {
                    error("Unexpected package received from installer: ${installIntent.`package`}")
                }
                if (installIntent.action != "android.content.pm.action.CONFIRM_INSTALL") {
                    error("Unexpected action received from installer: ${installIntent.action}")
                }

                context.startActivity(installIntent)
            }

            PackageInstaller.STATUS_SUCCESS -> Log.i("SelfUpdater", "Install succeeded!")

            PackageInstaller.STATUS_FAILURE,
            PackageInstaller.STATUS_FAILURE_ABORTED,
            PackageInstaller.STATUS_FAILURE_BLOCKED,
            PackageInstaller.STATUS_FAILURE_CONFLICT,
            PackageInstaller.STATUS_FAILURE_INCOMPATIBLE,
            PackageInstaller.STATUS_FAILURE_INVALID,
            PackageInstaller.STATUS_FAILURE_STORAGE ->
                Log.e("SelfUpdater", "Install failed! $status: $message")

            else -> Log.e("SelfUpdater", "Unrecognized status received from installer: $status")
        }
    }

    companion object {
        const val PACKAGE_INSTALLED_ACTION = "me.evgfilim1.mafia_companion.INSTALL_COMPLETE"
        private val KNOWN_INSTALLERS = setOf(
            "com.android.packageinstaller",
            "com.google.android.packageinstaller",
        )
    }
}
