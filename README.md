# PopCornBox — version Apple Watch

Application watchOS SwiftUI qui affiche les films et séries populaires de TMDB,
permet de les rechercher et de consulter leur synopsis et leur distribution.

## Tests

Deux cibles de test sont configurées dans le schéma partagé `PopCornBox` :

| Cible | Type | Portée |
| --- | --- | --- |
| `PopCornBoxTests` | Tests unitaires (31 tests) | Réseau, décodage JSON, modèle et machine à états du ViewModel |
| `PopCornBoxUITests` | Tests d'interface (7 tests) | Navigation, listes, détails, états vides et erreurs avec bouton « Réessayer » |

### Lancer tous les tests

Depuis le répertoire du projet :

```bash
xcrun simctl boot "Apple Watch Series 11 (46mm)"
xcodebuild -project PopCornBox.xcodeproj -scheme PopCornBox \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' \
  CODE_SIGNING_ALLOWED=NO test
```

Dans Xcode : sélectionner le schéma `PopCornBox`, un simulateur watchOS, puis `Cmd + U`.

### Ce qui est couvert

- **Recherche** : encodage des caractères spéciaux (`&`, `?`, accents), espaces, requête vide, anti-rebond.
- **Réseau** : statuts HTTP 401/429/5xx, corps d'erreur, JSON invalide, perte de connexion, timeout, URL invalide (plus de crash).
- **Données** : champs absents ou `null`, images absolues, repli pour synopsis/titre vides, casting partiel.
- **ViewModel** : chargement, succès, erreur, reprise après erreur, recherche concurrente (réponses hors ordre) et annulation silencieuse.
- **Interface** : accès aux écrans Films/Séries, navigation vers les détails, liste vide, message d'erreur et bouton « Réessayer ».

Les tests d'interface utilisent des données locales injectées au lancement
(`--uitests-mock`, `--uitests-empty`, `--uitests-error`) : aucun appel réseau réel,
donc aucun quota API consommé et aucun résultat dépendant de la connexion.
