# TP 5 – Widget d'écran d'accueil natif (Jetpack Glance) depuis Flutter

ISET Bizerte – Atelier Développement Mobile Natif – SEM3

Un widget Android, écrit en Kotlin avec Jetpack Glance, affiche sur l'écran d'accueil la dernière mesure envoyée par l'application Flutter via le canal `widget/maj`.

## Fonctionnalités

- **Étape 1** : widget statique (`MesureWidget`, `MesureWidgetReceiver`, `mesure_widget_info.xml`, déclaration dans le Manifest).
- **Étape 2** : l'app Flutter envoie la mesure, le titre, l'unité et le seuil. Le widget les affiche avec l'heure.
- **Étape 3** : fond rouge et « ALERTE » quand la mesure atteint le seuil ; un clic ouvre l'app ; le bouton ↻ relit la température de la batterie, même app fermée.
- **Étape 4** : mise à jour automatique par WorkManager toutes les ~15 min (planifiée dans `onEnabled()`, annulée dans `onDisabled()`).
- **Exercice 1** : widget adaptatif (1 × 1 : valeur seule ; 4 × 1 : une ligne ; 2 × 2 : complet).

Les réponses aux questions et la fiche projet sont dans [`REPONSES_TP5.md`](REPONSES_TP5.md).

## Lancer

```bash
flutter run
```

Ensuite : appui long sur l'écran d'accueil → Widgets → tp5_widget, ou bouton « Ajouter » dans l'app.

## Fichiers principaux

```
lib/main.dart                                   interface Flutter + CanalWidget
android/app/src/main/kotlin/com/example/tp5_widget/
  MainActivity.kt          canal widget/maj
  MesureWidget.kt          interface du widget (Glance)
  MesureWidgetReceiver.kt  récepteur + planification WorkManager
  WidgetEtat.kt            état du widget (DataStore) + WidgetMaj.enregistrer
  SourceMesure.kt          température batterie (capteur de démo)
  RafraichirAction.kt      action du bouton ↻
  WidgetWorker.kt          mise à jour périodique
android/app/src/main/res/xml/mesure_widget_info.xml
```
