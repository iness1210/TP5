package com.example.tp5_widget

import android.content.Context
import android.os.Process
import android.util.Log
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback

// Exécutée dans notre application quand on touche ↻, même si elle est fermée
class RafraichirAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        // Trace pour vérifier dans Logcat quel processus exécute l'action (question de l'étape 3)
        Log.d("TP5", "RafraichirAction : pid=${Process.myPid()} package=${context.packageName}")
        SourceMesure.lireEtPublier(context)
    }
}
