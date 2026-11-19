# TP 5 – Widget d'écran d'accueil natif (Jetpack Glance) – Réponses

Nom et prénom : ................................  Groupe : ......

## Partie 1 – Vérifiez votre compréhension

**1. Pourquoi le hot reload ne change-t-il jamais le widget ?**
Le hot reload ne réinjecte que le code Dart dans la VM Dart. Le widget est écrit en Kotlin (Glance), compilé dans l'APK, et dessiné par le launcher à partir de RemoteViews. Pour modifier le widget, il faut recompiler le code natif et réinstaller l'application : arrêter l'app et relancer `flutter run`.

**2. Quelle différence entre `androidx.compose.material3.Text` et `androidx.glance.text.Text` ?**
`compose.material3.Text` est un composant Compose dessiné directement par l'application dans sa propre fenêtre. `glance.text.Text` est un composant Glance traduit en RemoteViews (un `TextView`) que le launcher dessine. Un composant Compose dans un widget provoque l'erreur « Impossible de charger le widget ».

**3. Qui exécute le code de dessin du widget ?**
Le launcher. Notre application (Glance) ne fait que produire une description RemoteViews, et le launcher la dessine dans son propre processus.

## Étape 1 – Question

**Retirer `<receiver …>` du Manifest : que devient le widget ?**
Le widget disparaît de la liste des widgets du launcher. Un widget déjà posé ne peut plus être chargé (« Impossible de charger le widget ») ou il est retiré. Sans le récepteur déclaré avec la meta-data `android.appwidget.provider`, le système ne sait pas que l'application fournit un widget.

## Étape 2 – Question

**Supprimer tous les widgets, envoyer, puis reposer un widget : qu'affiche-t-il ?**
Il affiche « Capteur », « — » et « en attente ». L'envoi répond « Aucun widget sur l'écran d'accueil » (0 widget).
La valeur est perdue parce que l'état est stocké **par widget posé** (un fichier DataStore par `GlanceId`). `enregistrer()` boucle sur les `GlanceId` existants : la liste est vide, donc rien n'est écrit. Le nouveau widget reçoit un nouvel identifiant avec un état vide.

## Étape 3 – Question

**L'app était fermée : quel processus a exécuté `RafraichirAction` ? Comment le vérifier ?**
Le processus de **notre application** (`com.example.tp5_widget`). Le clic envoie un `PendingIntent` vers notre application. Le système relance alors notre processus, qui exécute l'`ActionCallback`. Le launcher n'exécute jamais notre code.
Vérification dans Logcat : `RafraichirAction` écrit `Log.d("TP5", "RafraichirAction : pid=… package=…")`. Dans Logcat, filtrez sur `tag:TP5` : la ligne est rattachée au package `com.example.tp5_widget`, et son PID est différent de celui du launcher. On voit aussi le démarrage du processus (« Start proc … com.example.tp5_widget ») juste avant.

## Étape 4 – Question

**Un ESP32 envoie une mesure toutes les 5 s. Pourquoi ne pas mettre à jour le widget toutes les 5 s ?**
1. **Batterie** : chaque mise à jour réveille l'application, lit et écrit le DataStore, puis transmet des RemoteViews au launcher par IPC. Toutes les 5 s, cela empêche le mode Doze et vide la batterie.
2. **Limites du système** : WorkManager impose un minimum de 15 min pour un travail périodique. Android limite aussi le travail en arrière-plan (Doze, App Standby, restrictions des constructeurs), et le launcher peut regrouper ou ignorer des mises à jour trop fréquentes.
3. (bonus) Un widget sert à jeter un coup d'œil : une valeur rafraîchie toutes les 15 min suffit, et le bouton ↻ permet d'avoir la valeur actuelle. Pour une alerte urgente, il faut un service au premier plan ou une notification push (TP 4).

## Questions de compréhension

**1. Pourquoi une interface Flutter ne peut-elle pas être affichée dans un widget ?**
Le widget est dessiné par le launcher, dans un autre processus, à partir de RemoteViews : une description limitée à un petit ensemble de vues Android autorisées. Le moteur Flutter dessine chaque pixel lui-même dans sa propre surface. Il ne peut pas produire de RemoteViews et ne tourne pas dans le processus du launcher.

**2. Deux différences entre Jetpack Compose et Jetpack Glance.**
- Qui dessine : Compose est dessiné par l'application ; avec Glance, l'application produit des RemoteViews et le launcher les dessine.
- Mise à jour : Compose se recompose automatiquement à chaque changement d'état ; Glance ne se redessine que sur demande (`update()` / `updateAll()`).
- (aussi) Glance a ses propres composants (`androidx.glance.*`) et utilise `GlanceModifier` au lieu de `Modifier`. Les clics sont des actions (`actionStartActivity`, `actionRunCallback`), pas des lambdas.

**3. Où est stockée la valeur affichée ? Pourquoi un état par widget ?**
Dans un fichier DataStore Preferences géré par Glance (paires clé → valeur : `titre`, `valeur`, `unite`, `seuil`, `heure`). Il y en a un par widget posé, identifié par son `GlanceId`. Chaque instance peut ainsi avoir sa propre configuration et sa propre taille, et afficher une mesure différente. Quand on retire un widget, son état est supprimé avec lui.

**4. Pourquoi `updateAppWidgetState` et `updateAll` dans une coroutine ?**
Ce sont des fonctions `suspend` : elles lisent et écrivent un fichier (DataStore) et communiquent avec l'`AppWidgetManager`. Ces opérations sont lentes et ne doivent pas bloquer le thread principal. Une fonction `suspend` ne peut être appelée que depuis une coroutine ou une autre fonction `suspend`. C'est pour ça qu'on utilise `scope.launch { … }` dans `MainActivity`, `CoroutineWorker` dans le worker et `ActionCallback.onAction`, qui est `suspend`.

**5. Pourquoi planifier le worker dans `onEnabled()` plutôt qu'au démarrage de l'app ?**
`onEnabled()` est appelée à la pose du **premier** widget, et `onDisabled()` au retrait du **dernier**. Le travail tourne donc seulement quand un widget existe. Il démarre même si l'utilisateur n'ouvre jamais l'application, et il ne consomme pas de batterie pour rien si aucun widget n'est posé. Au démarrage de l'app, on planifierait un travail inutile sans widget, et rien ne serait planifié si l'app n'était jamais ouverte.

**6. Pourquoi `updatePeriodMillis = 0` ?**
La mise à jour automatique du système a un minimum de 30 min, elle n'est pas fiable (elle peut être retardée et réveille l'appareil) et on ne peut pas la contrôler ni l'annuler finement. On la désactive et on confie la mise à jour périodique à WorkManager (étape 4), qui respecte Doze et peut avoir des contraintes (réseau…).

## Exercice 4 – Fiche projet

> Fiche correspondant au projet de démonstration livré. Pour un vrai projet IoT, remplacez la source de mesure et les valeurs par celles de votre capteur.

| Question | Réponse |
|---|---|
| Quelle mesure le widget affiche-t-il ? (nom, unité) | La température simulée envoyée depuis l'application, en °C. L'action ↻ et le worker utilisent la température de la batterie Android comme source de démonstration. |
| Quel seuil déclenche l'alerte rouge ? | La valeur atteint ou dépasse le seuil réglé dans l'application (38 °C par défaut). |
| Qui met à jour le widget ? | L'application Flutter quand on appuie sur « Envoyer au widget » ; le `WidgetWorker` relit la température de la batterie environ toutes les 15 minutes. |
| Que doit faire un clic sur le widget ? ↻ ? | Un clic sur le widget ouvre l'application. ↻ relit la température de la batterie et actualise le widget, même si l'application est fermée. |
| Que voit l'utilisateur si la source ne fournit pas de température ? | La dernière valeur connue et son heure restent affichées ; `SourceMesure.lireEtPublier()` n'écrase pas l'état si la température de batterie est indisponible. |

## Exercices réalisés dans le code

- **Exercice 1 (widget adaptatif)** : fait dans `MesureWidget.kt`. `SizeMode.Responsive` avec trois tailles : 1 × 1 affiche la valeur seule, 4 × 1 affiche titre, valeur et seuil sur une ligne, et 2 × 2 affiche le widget complet. `minResizeWidth/Height="40dp"` est ajouté dans `mesure_widget_info.xml` pour pouvoir réduire le widget à 1 × 1.
- **Exercices 2 et 3 (Firebase)** : non intégrés dans ce projet de démonstration, car aucune base Firebase ni URL de projet n'est fournie. Pour les réaliser sur votre projet IoT, appelez `CanalWidget.mettreAJour` dans le `onValue.listen`, puis remplacez `temperatureBatterie` par `lireFirebase()` dans la source utilisée par le bouton ↻ et le worker (avec la permission INTERNET et la contrainte réseau).
