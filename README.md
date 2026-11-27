# PopCornBox — Widget iOS

Le projet a été transformé : l'ancienne application à onglets (Films / Séries) est remplacée par un **widget WidgetKit** affiché sur l'écran d'accueil.

![Logo PopCornBox](PopCornBox/logo.png)

## Structure

| Dossier / fichier | Rôle |
| --- | --- |
| `PopCornBoxWidget/` | **Extension WidgetKit** (toute la fonctionnalité active) |
| `PopCornBoxWidget/PopCornBoxWidget.swift` | Point d'entrée `@main` du bundle de widgets |
| `PopCornBoxWidget/PopularMediaWidget.swift` | Définition du widget, timeline provider et aperçus Xcode |
| `PopCornBoxWidget/ConfigurationAppIntent.swift` | Choix **Films** ou **Séries** (appui long → Modifier le widget) |
| `PopCornBoxWidget/WidgetData.swift` | Client TMDB dédié au widget + modèle d'affichage |
| `PopCornBoxWidget/WidgetViews.swift` | Vues `small` / `medium` / `large` |
| `PopCornBox/` | Application hôte minimale, obligatoire sur iOS pour contenir l'extension |
| `_legacy_app_sources/` | Anciennes vues et couche réseau de l'app, conservées mais **non compilées** |

## Comportement du widget

- Récupère le top des films ou des séries populaires via l'API TMDB (en français).
- Les affiches sont téléchargées puis intégrées à la timeline pour un rendu fiable.
- Tailles prises en charge : petit, moyen et grand widget.
- Un appui sur une entrée ouvre la fiche correspondante sur TMDB dans Safari.
- Rafraîchissement automatique toutes les 3 heures (politique `.after`).
- En cas d'erreur réseau, un état vide explicite est affiché.

## Utilisation

1. Ouvrir `PopCornBox.xcodeproj` dans Xcode.
2. Choisir la cible **PopCornBoxWidget** pour prévisualiser le widget dans Xcode, ou la cible **PopCornBox** pour installer l'app hôte sur un simulateur/appareil.
3. Installer l'app, revenir sur l'écran d'accueil, appui long → `+` → rechercher **PopCornBox**.
4. Appui long sur le widget → **Modifier le widget** pour choisir Films ou Séries.

> Le widget nécessite un accès réseau. Le token TMDB se trouve dans `PopCornBoxWidget/WidgetData.swift` (même jeton que l'ancienne application).

## Tests

La cible **PopCornBoxWidgetTests** contient 32 tests unitaires (scheme du même nom) qui couvrent les situations susceptibles de gêner un utilisateur :

- **Réseau** : endpoint film/série, en-têtes d'authentification, erreur HTTP, JSON malformé, perte de connexion.
- **Données TMDB** : classement des résultats, limite, champs absents (`title`/`name`), liste vide, lien de détail.
- **Affiches** : téléchargement réussi, affiche manquante ou en échec (l'entrée reste affichée).
- **Configuration** : choix Films/Séries, valeurs par défaut, icônes et titres associés.
- **Timeline** : propagation du type configuré, entries vides en cas de panne, rafraîchissement à 3 heures, aperçu sans réseau.

Lancer les tests :

```bash
xcodebuild -project PopCornBox.xcodeproj -scheme PopCornBoxWidgetTests \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Pour rendre ces tests possibles, `WidgetTMDBClient` accepte désormais une `URLSession` injectable et le `PopularMediaProvider` accepte un client injectable (un faux client est utilisé dans les tests).
