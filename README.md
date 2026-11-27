# PopCornBox

Application iOS SwiftUI de découverte de films et séries, avec un quiz culturel généré à partir du catalogue [TMDB](https://www.themoviedb.org/).

![Icône PopCornBox](PopCornBox/PopCornBox/logo.png)

## Fonctionnalités

- **Accueil** : présentation de l'application et du logo PopCornBox.
- **Films / Séries** : catalogue popularité (TMDB, langue `fr-FR`), recherche instantanée (délai de 0,5 s), fiche détaillée avec affiche, note, année et synopsis.
- **Quiz** : 10 questions générées de façon déterministe à partir des films, séries et castings :
  - image (backdrop sans titre), acteur, personnage, année, genre et note ;
  - 4 propositions par question, score, feedback immédiat et écran de résultat ;
  - possibilité de recommencer une partie.
- **Tests unitaires** : 30 tests sur le générateur de questions et le `QuizViewModel`, avec un client TMDB simulé (`MockTMDBClient`).

## Structure du dépôt

```
.
├── PopCornBox/                 # Application iOS
│   ├── PopCornBoxApp.swift     # Point d'entrée @main
│   ├── ContentView.swift       # TabView (Accueil / Films / Séries / Quiz)
│   ├── Models/                 # FilmSerieItem, QuizQuestion, QuizGenerator
│   ├── Networking/             # Client et modèles TMDB
│   ├── ViewModels/             # BoxOfficeViewModel, QuizViewModel
│   ├── Views/                  # Écrans SwiftUI
│   └── Assets.xcassets/        # Icône, couleur d'accent, logo
├── PopCornBoxTests/            # Tests unitaires
├── PopCornBoxUITests/          # Tests d'interface
└── PopCornBox.xcodeproj        # Projet Xcode (cibles PopCornBox et PopCornBoxTests)
```

## Prérequis

- macOS avec **Xcode 26.x** (SDK iOS 26.2)
- Swift 5.0
- Aucun gestionnaire de dépendances (pas de CocoaPods ni de Swift Package à installer)
- Connexion réseau pour les appels à l'API TMDB

> Sur la branche `main`, le token de lecture TMDB est embarqué dans `PopCornBox/Networking/TMDBClient.swift`. Pour une mise en production, le déplacer dans une configuration sécurisée ou un service backend.

## Lancer le projet

```bash
git clone https://github.com/Valentin088/projet_IOS_HOFF_HOJA_ABABSA.git
cd projet_IOS_HOFF_HOJA_ABABSA
open PopCornBox.xcodeproj
```

Dans Xcode :

1. Sélectionne un simulateur iOS (ou un appareil connecté).
2. Choisis le schéma **PopCornBox**.
3. Lance avec **⌘R**.

## Lancer les tests

Depuis Xcode : **⌘U** avec le schéma `PopCornBox` sélectionné.

En ligne de commande :

```bash
xcrun simctl list devices available   # pour connaître un simulateur installé
xcodebuild test \
  -project PopcornBox.xcodeproj \
  -scheme PopCornBox \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Branches

- `main` : version iOS principale (application à onglets + quiz).
- `watch` : prototype Apple Watch.
- `widget` : prototype WidgetKit.

## Auteurs

- Valentin Hoja — [@Valentin088](https://github.com/Valentin088)
- Rafael Hoff — [@Rafrigirateur](https://github.com/Rafrigirateur)
- Rayan Ababsa — [@raracodkebab](https://github.com/raracodkebab)
