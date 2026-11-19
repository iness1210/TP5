package com.example.tp5_widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalSize
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// Exercice 1 : tailles de référence (1 × 1, 4 × 1, 2 × 2)
private val PETIT = DpSize(57.dp, 57.dp)
private val LARGE = DpSize(250.dp, 57.dp)
private val NORMAL = DpSize(110.dp, 110.dp)

class MesureWidget : GlanceAppWidget() {

    // Exercice 1 : Glance dessine une version par taille et le launcher choisit la bonne
    override val sizeMode = SizeMode.Responsive(setOf(PETIT, LARGE, NORMAL))

    // Appelée par Glance chaque fois que le widget doit être (re)dessiné
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()          // l'état de CE widget
            val titre = prefs[CleWidget.TITRE] ?: "Capteur"
            val valeur = prefs[CleWidget.VALEUR]               // null tant que rien n'est reçu
            val unite = prefs[CleWidget.UNITE] ?: ""
            val heure = prefs[CleWidget.HEURE]
            val seuil = prefs[CleWidget.SEUIL]
            val alerte = valeur != null && seuil != null && valeur >= seuil

            GlanceTheme {
                Contenu(titre, valeur, unite, heure, seuil, alerte)
            }
        }
    }
}

// Couleurs fixes : identiques en thème clair (day) et sombre (night)
private val ROUGE = ColorProvider(day = Color(0xFFB3261E), night = Color(0xFFB3261E))
private val BLANC = ColorProvider(day = Color.White, night = Color.White)

@Composable
private fun Contenu(
    titre: String, valeur: Float?, unite: String, heure: Long?, seuil: Float?, alerte: Boolean
) {
    val fond = if (alerte) ROUGE else GlanceTheme.colors.widgetBackground
    val couleur = if (alerte) BLANC else GlanceTheme.colors.onSurface
    val texteValeur = if (valeur == null) "—" else "%.1f %s".format(valeur, unite)
    val taille = LocalSize.current
    val fondModif = GlanceModifier
        .fillMaxSize()
        .background(fond)
        .cornerRadius(16.dp)
        .clickable(actionStartActivity<MainActivity>())              // clic = ouvrir l'app

    // Exercice 1 – 1 × 1 : uniquement la valeur
    if (taille.height < 100.dp && taille.width < 200.dp) {
        Box(fondModif.padding(4.dp), contentAlignment = Alignment.Center) {
            Text(texteValeur, style = TextStyle(color = couleur, fontSize = 16.sp, fontWeight = FontWeight.Bold))
        }
        return
    }
    // Exercice 1 – 4 × 1 : titre, valeur et seuil sur une ligne
    if (taille.height < 100.dp) {
        Row(fondModif.padding(horizontal = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(titre, style = TextStyle(color = couleur, fontSize = 14.sp), modifier = GlanceModifier.defaultWeight())
            Text(texteValeur, style = TextStyle(color = couleur, fontSize = 20.sp, fontWeight = FontWeight.Bold))
            Text(
                if (seuil == null) "" else "  seuil %.0f".format(seuil),
                style = TextStyle(color = couleur, fontSize = 12.sp)
            )
        }
        return
    }

    Column(modifier = fondModif.padding(12.dp)) {
        Text(titre, style = TextStyle(color = couleur, fontSize = 14.sp))
        Text(
            texteValeur,
            style = TextStyle(color = couleur, fontSize = 28.sp, fontWeight = FontWeight.Bold)
        )
        Spacer(GlanceModifier.defaultWeight())                        // pousse la ligne en bas
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                when {
                    alerte -> "ALERTE"
                    heure == null -> "en attente"
                    else -> "à " + formatHeure(heure)
                },
                style = TextStyle(color = couleur, fontSize = 12.sp, fontWeight = FontWeight.Bold),
                modifier = GlanceModifier.defaultWeight()
            )
            Text(
                "↻",
                style = TextStyle(color = couleur, fontSize = 20.sp, fontWeight = FontWeight.Bold),
                modifier = GlanceModifier
                    .padding(horizontal = 8.dp)
                    .clickable(actionRunCallback<RafraichirAction>())  // clic = relire
            )
        }
    }
}

private fun formatHeure(ms: Long): String =
    SimpleDateFormat("HH:mm", Locale.FRANCE).format(Date(ms))
