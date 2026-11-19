package com.example.tp5_widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

// Fait le lien entre le launcher (qui envoie des broadcasts) et notre widget Glance
class MesureWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MesureWidget()

    // Appelée quand le PREMIER widget est posé
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetWorker.planifier(context)
    }

    // Appelée quand le DERNIER widget est retiré
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetWorker.annuler(context)
    }
}
