# PopCornBox — Version Firebase

Application iOS SwiftUI de découverte de films et séries avec **authentification Firebase**, **favoris personnalisés**, **scores de quiz** et **historique** par compte utilisateur.

![Logo PopCornBox](PopcornBox/logo.png)

## Fonctionnalités

- **Accueil** : présentation de l'application et du logo PopCornBox.
- **Films / Séries** : catalogue popularité (TMDB, langue `fr-FR`), recherche instantanée, ajout/retrait des favoris depuis les listes.
- **Détails** : fiche complète avec affiche, synopsis, casting, et bouton favori.
- **Quiz** : 10 questions générées de façon déterministe, score sauvegardé par utilisateur, historique des quiz récents.
- **Profil** : gestion du compte, mes favoris, historique des quiz, déconnexion, suppression de compte.
- **Authentification Firebase** :
  - Connexion / inscription avec email et mot de passe.
  - Connexion avec **Google** (OAuth).
  - Création de compte sans Google (email/mot de passe uniquement).
  - Réinitialisation de mot de passe.
  - Toutes les données (favoris, scores, historique) sont liées au compte utilisateur via Firestore.

## Structure du dépôt

```
.
├── Package.swift                       # Dépendances Swift Package Manager (Firebase, GoogleSignIn)
├── PopcornBox/                         # Application iOS
│   ├── PopcornBoxApp.swift             # Point d'entrée @main
│   ├── ContentView.swift               # Gestion de l'authentification + TabView
│   ├── Models/
│   │   ├── FilmSerieItem.swift         # Modèle film/série
│   │   ├── QuizQuestion.swift          # Modèle question de quiz
│   │   └── UserModels.swift            # Modèles utilisateur (profil, favori, score, historique)
│   ├── Networking/                     # Client et modèles TMDB
│   ├── Services/
│   │   ├── AuthService.swift           # Authentification Firebase (protocole + implémentation)
│   │   └── UserDataService.swift       # Données Firestore (favoris, scores, historique)
│   ├── ViewModels/
│   │   ├── BoxOfficeViewModel.swift    # Catalogue films/séries
│   │   ├── QuizViewModel.swift         # Logique du quiz
│   │   └── AuthViewModel.swift         # État d'authentification et données utilisateur
│   ├── Views/
│   │   ├── HomeView.swift              # Écran d'accueil
│   │   ├── MoviesView.swift            # Liste des films (+ favoris)
│   │   ├── SeriesView.swift            # Liste des séries (+ favoris)
│   │   ├── QuizView.swift              # Quiz avec sauvegarde du score
│   │   ├── DetailsView.swift           # Fiche détaillée (+ bouton favori)
│   │   ├── AuthenticationView.swift    # Connexion / inscription / Google
│   │   ├── ProfileView.swift           # Profil utilisateur
│   │   ├── FavoritesView.vue           # Liste des favoris
│   │   └── QuizHistoryView.vue         # Historique des quiz
│   ├── item/FilmSerieItemView.swift    # Ligne de liste avec bouton cœur favori
│   ├── UITesting.swift                 # Client mock et mode test UI
│   └── Assets.xcassets/                # Icône, couleur d'accent, logo
├── PopcornBoxTests/                    # Tests unitaires
│   ├── MockTMDBClient.swift            # Client TMDB simulé
│   ├── FirebaseMocks.swift             # Mocks AuthService et UserDataService
│   ├── AuthViewModelTests.swift        # Tests d'authentification
│   ├── UserDataViewModelTests.swift    # Tests favoris / scores / historique
│   └── QuizTests.swift                 # Tests du quiz existants
├── PopcornBoxUITests/                  # Tests d'interface
│   └── PopcornBoxUITests.swift         # Tests UI (lancement, onglets, quiz, favoris, profil)
├── PopcornBox.xcodeproj                # Projet Xcode
└── README.md
```

## Prérequis

- macOS avec **Xcode 26.x** (SDK iOS 26.2)
- Swift 5.0
- **CocoaPods ou Swift Package Manager** pour Firebase
- Compte [Firebase](https://firebase.google.com/) avec un projet configuré
- Application iOS enregistrée dans Firebase avec `GoogleService-Info.plist`

## Installation de Firebase

### 1. Créer un projet Firebase

1. Aller sur la [console Firebase](https://console.firebase.google.com/).
2. Créer un nouveau projet.
3. Ajouter une application iOS (bundle ID : `lez.popcornbox`).
4. Télécharger le fichier `GoogleService-Info.plist` et l'ajouter au projet Xcode (dans le dossier `PopcornBox/`).
5. Activer **Authentication** :
   - Méthode **Email/Mot de passe**.
   - Méthode **Google**.
6. Activer **Firestore Database** (mode test ou production).

### 2. Ajouter les dépendances via Swift Package Manager

Dans Xcode :

1. Ouvrir `PopcornBox.xcodeproj`.
2. Menu **File > Add Packages**.
3. Ajouter les URLs suivantes :
   - `https://github.com/firebase/firebase-ios-sdk.git` (version 10.25.0+)
     - Produits : `FirebaseAuth`, `FirebaseFirestore`, `FirebaseCore`
   - `https://github.com/google/GoogleSignIn-iOS.git` (version 7.0.0+)
     - Produit : `GoogleSignIn`

### 3. Configurer l'URL Schemes pour Google Sign-In

Dans le projet Xcode, onglet **Info > URL Types** :

- Ajouter un type d'URL avec :
  - **Identifier** : `com.googleusercontent.apps.<VOTRE_CLIENT_ID>`
  - **URL Schemes** : `com.googleusercontent.apps.<VOTRE_CLIENT_ID>` (trouvé dans `GoogleService-Info.plist`)

### 4. Initialiser Firebase

Dans `PopcornBoxApp.swift`, ajouter dans `init()` :

```swift
import FirebaseCore
import FirebaseAuth

@main
struct PopcornBoxApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Lancer le projet

```bash
git clone https://github.com/Valentin088/projet_IOS_HOFF_HOJA_ABABSA.git
cd projet_IOS_HOFF_HOJA_ABABSA
git checkout main-firebase
open PopcornBox.xcodeproj
```

Dans Xcode :

1. Sélectionner un simulateur iOS (ou un appareil connecté).
2. Choisir le schéma **PopcornBox**.
3. Lancer avec **⌘R**.

## Lancer les tests

### Tests unitaires

Depuis Xcode : **⌘U** avec le schéma `PopcornBox` sélectionné.

Ou en ligne de commande :

```bash
xcodebuild test \
  -project PopcornBox.xcodeproj \
  -scheme PopcornBox \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Tests UI

Les tests UI se lancent avec l'argument `-UITesting` pour utiliser des données simulées (pas d'appel réseau Firebase ni TMDB).

```bash
xcodebuild test \
  -project PopcornBox.xcodeproj \
  -scheme PopcornBox \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:PopcornBoxUITests
```

## Couverture des tests

| Type | Nombre | Couverture |
|------|--------|------------|
| Tests unitaires | ~35 | Générateur de quiz, QuizViewModel, AuthViewModel (connexion, inscription, Google, déconnexion, suppression), UserDataViewModel (favoris, scores, historique) |
| Tests UI | ~14 | Lancement, navigation onglets, listes films/séries, détails, recherche, flux complet du quiz, rejoue, feedback, authentification, profil, favoris (liste + détails), historique des quiz |

## Architecture

- **Protocoles** (`AuthServiceProtocol`, `UserDataServiceProtocol`) : injection de dépendances pour tester sans Firebase.
- **Mocks** (`MockAuthService`, `MockUserDataService`) : tests unitaires isolés.
- **Mode UITesting** : quand l'argument `-UITesting` est passé, l'utilisateur est automatiquement connecté avec un profil simulé et les données sont en mémoire (pas de Firestore).
- **Firestore** : collections `users/{uid}/favorites`, `quizScores`, `quizHistory`.

## Auteurs

- Valentin Hoja — [@Valentin088](https://github.com/Valentin088)
- Rafael Hoff — [@Rafrigirateur](https://github.com/Rafrigirateur)
- Rayan Ababsa — [@raracodkebab](https://github.com/raracodkebab)
