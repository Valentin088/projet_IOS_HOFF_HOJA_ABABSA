# PopCornBox — Widget iOS

Le projet a été transformé : l'ancienne application à onglets (Films / Séries) est remplacée par un **widget WidgetKit** affiché sur l'écran d'accueil.

## Structure

| Dossier / fichier | Rôle |
| --- | --- |
| `PopCornBoxWidget/` | **Extension WidgetKit** (toute la fonctionnalité active) |
| `PopCornBoxWidget/PopCornBoxWidget.swift` | Point d'entrée `@main` du bundle de widgets |
| `PopCornBoxWidget/PopularMediaWidget.swift` | Définition du widget, timeline provider et aperçus Xcode |
| `PopCornBoxWidget/ConfigurationAppIntent.swift` | Choix **Films** ou **Séries** (appui long → Modifier le widget) |
| `PopCornBoxWidget/WidgetData.swift` | Client TMDB dédié au widget + modèle d'affichage |
| `PopCornBoxWidget/WidgetViews.swift` | Vues `small` / `medium` / `large` |
| `ok/` | Application hôte minimale, obligatoire sur iOS pour contenir l'extension |
| `_legacy_app_sources/` | Anciennes vues et couche réseau de l'app, conservées mais **non compilées** |

## Comportement du widget

- Récupère le top des films ou des séries populaires via l'API TMDB (en français).
- Les affiches sont téléchargées puis intégrées à la timeline pour un rendu fiable.
- Tailles prises en charge : petit, moyen et grand widget.
- Un appui sur une entrée ouvre la fiche correspondante sur TMDB dans Safari.
- Rafraîchissement automatique toutes les 3 heures (politique `.after`).
- En cas d'erreur réseau, un état vide explicite est affiché.

## Utilisation

1. Ouvrir `ok.xcodeproj` dans Xcode.
2. Choisir la cible **PopCornBoxWidget** pour prévisualiser le widget dans Xcode, ou la cible **ok** pour installer l'app hôte sur un simulateur/appareil.
3. Installer l'app, revenir sur l'écran d'accueil, appui long → `+` → rechercher **PopCornBox**.
4. Appui long sur le widget → **Modifier le widget** pour choisir Films ou Séries.

> Le widget nécessite un accès réseau. Le token TMDB se trouve dans `PopCornBoxWidget/WidgetData.swift` (même jeton que l'ancienne application).
