import Foundation

/// Une œuvre du catalogue et son casting, utilisée comme source des questions.
struct QuizSource: Identifiable, Equatable {
    let item: FilmSerieItem
    let cast: [Cast]

    var id: String { "\(item.kind)-\(item.id)" }
}

/// Les différentes familles de questions du quizz.
enum QuizQuestionKind: String, CaseIterable, Equatable {
    case image
    case actor
    case character
    case year
    case genre
    case rating

    var label: String {
        switch self {
        case .image: return "Image"
        case .actor: return "Acteurs"
        case .character: return "Personnages"
        case .year: return "Année"
        case .genre: return "Genre"
        case .rating: return "Note"
        }
    }
}

/// Une question du quizz. `correctAnswerIndex` est l'indice de la bonne réponse
/// dans `options`, ce qui rend le modèle facile à vérifier en tests unitaires.
struct QuizQuestion: Identifiable, Equatable {
    let id: String
    let kind: QuizQuestionKind
    let prompt: String
    let options: [String]
    let correctAnswerIndex: Int
    /// Image affichée avec la question. Jamais une affiche contenant le titre.
    let imageURL: URL?
    let imageIsPortrait: Bool
    let mediaKind: MediaType
    let explanation: String

    var correctAnswer: String? {
        guard options.indices.contains(correctAnswerIndex) else { return nil }
        return options[correctAnswerIndex]
    }

    /// Indique si l'index proposé correspond à la bonne réponse.
    func isCorrect(answerIndex: Int) -> Bool {
        answerIndex == correctAnswerIndex
    }
}

// MARK: - Générateur

/// Construit les questions du quizz à partir du catalogue PopCornBox.
///
/// L'algorithme est volontairement déterministe (pas de hasard) afin que les
/// questions soient reproductibles et testables. Les affiches sont remplacées
/// par des images de fond (backdrops) ou des portraits d'acteurs : aucun titre
/// n'apparaît dans l'image, pour ne pas dévoiler la réponse.
enum QuizGenerator {
    nonisolated static let optionCount = 4
    nonisolated static let defaultQuestionCount = 10
    nonisolated static let defaultSourceCount = 12

    /// Genres TMDB (identifiants → libellés français), pour les questions de genre.
    nonisolated static let genres: [Int: String] = [
        12: "Aventure", 14: "Fantastique", 16: "Animation", 18: "Drame",
        27: "Horreur", 28: "Action", 35: "Comédie", 36: "Histoire",
        37: "Western", 53: "Thriller", 80: "Crime", 99: "Documentaire",
        878: "Science-fiction", 9648: "Mystère", 10402: "Musique",
        10749: "Romance", 10751: "Famille", 10752: "Guerre",
        10759: "Action et aventure", 10762: "Documentaire",
        10763: "Actualités", 10764: "Divertissement",
        10765: "Science-fiction et fantastique", 10766: "Feuilleton",
        10767: "Talk-show", 10768: "Guerre et politique", 10770: "Téléfilm"
    ]

    /// Mélange films et séries en alternant les deux listes pour que le quizz
    /// couvre réellement « tous les films et séries du moment ».
    nonisolated static func merge(movies: [FilmSerieItem], series: [FilmSerieItem]) -> [FilmSerieItem] {
        var merged: [FilmSerieItem] = []
        let maxCount = max(movies.count, series.count)

        for index in 0..<maxCount {
            if index < movies.count { merged.append(movies[index]) }
            if index < series.count { merged.append(series[index]) }
        }
        return merged
    }

    /// Génère au maximum `count` questions en alternant les familles de
    /// questions. Retourne une liste vide s'il n'y a pas assez de titres
    /// distincts pour composer des propositions.
    nonisolated static func makeQuestions(
        from sources: [QuizSource],
        count: Int = defaultQuestionCount
    ) -> [QuizQuestion] {
        let pool = unique(sources)
        guard pool.count >= optionCount, count > 0 else { return [] }

        let kinds = QuizQuestionKind.allCases
        let total = min(count, pool.count * kinds.count)
        var questions: [QuizQuestion] = []
        var kindOffset = 0
        var sourceIndex = 0
        let maxAttempts = total * kinds.count * 2

        while questions.count < total && questions.count + sourceIndex < maxAttempts {
            let kind = kinds[kindOffset % kinds.count]
            let source = pool[sourceIndex % pool.count]

            if let question = makeQuestion(kind: kind, source: source, pool: pool, number: questions.count) {
                questions.append(question)
            }

            sourceIndex += 1
            kindOffset += 1
        }

        return questions
    }

    // MARK: - Fabrication d'une question

    nonisolated private static func makeQuestion(
        kind: QuizQuestionKind,
        source: QuizSource,
        pool: [QuizSource],
        number: Int
    ) -> QuizQuestion? {
        switch kind {
        case .image:
            // On exige un backdrop : une affiche pourrait contenir le titre.
            guard let backdropURL = source.item.backdropURL,
                  let base = options(correct: source.item.title, others: pool.map(\.item.title)) else { return nil }
            let (choices, correctIndex) = rotated(base, number: number)
            let article = source.item.kind == .movie ? "ce film" : "cette série"
            let explanation = "« \(source.item.title) » fait partie des \(source.item.kind == .movie ? "films" : "séries") populaires du moment."
            return QuizQuestion(
                id: questionID(kind, source, number),
                kind: kind,
                prompt: "Quel est le titre de \(article) ?",
                options: choices,
                correctAnswerIndex: correctIndex,
                imageURL: backdropURL,
                imageIsPortrait: false,
                mediaKind: source.item.kind,
                explanation: explanation
            )

        case .actor:
            guard let entry = castEntry(in: source, excludingCharacter: false),
                  let base = options(correct: entry.name, others: pool.flatMap(\.cast).map(\.name)) else { return nil }
            let (choices, correctIndex) = rotated(base, number: number)
            return QuizQuestion(
                id: questionID(kind, source, number),
                kind: kind,
                prompt: "Quel acteur interprète « \(entry.character) » dans « \(source.item.title) » ?",
                options: choices,
                correctAnswerIndex: correctIndex,
                imageURL: source.item.backdropURL,
                imageIsPortrait: false,
                mediaKind: source.item.kind,
                explanation: "\(entry.name) joue \(entry.character) dans « \(source.item.title) »."
            )

        case .character:
            guard let entry = castEntry(in: source, excludingCharacter: true),
                  let base = options(correct: entry.character, others: pool.flatMap(\.cast).map(\.character)) else { return nil }
            let (choices, correctIndex) = rotated(base, number: number)
            return QuizQuestion(
                id: questionID(kind, source, number),
                kind: kind,
                prompt: "Quel personnage \(entry.name) joue-t-il dans « \(source.item.title) » ?",
                options: choices,
                correctAnswerIndex: correctIndex,
                imageURL: entry.largeProfileURL ?? entry.profileURL,
                imageIsPortrait: true,
                mediaKind: source.item.kind,
                explanation: "Dans « \(source.item.title) », \(entry.name) interprète \(entry.character)."
            )

        case .year:
            guard let year = source.item.releaseYear,
                  let base = options(correct: String(year), others: pool.compactMap(\.item.releaseYear).map(String.init)) else { return nil }
            let (choices, correctIndex) = rotated(base, number: number)
            let title = source.item.title
            return QuizQuestion(
                id: questionID(kind, source, number),
                kind: kind,
                prompt: "En quelle année « \(title) » est-il sorti ?",
                options: choices,
                correctAnswerIndex: correctIndex,
                imageURL: source.item.backdropURL,
                imageIsPortrait: false,
                mediaKind: source.item.kind,
                explanation: "« \(title) » a été diffusé en \(year)."
            )

        case .genre:
            guard let genreID = source.item.genreIDs.first,
                  let genre = genres[genreID],
                  let base = options(
                    correct: genre,
                    others: pool.compactMap { $0.item.genreIDs.first }.compactMap { genres[$0] }
                  ) else { return nil }
            let (choices, correctIndex) = rotated(base, number: number)
            let title = source.item.title
            return QuizQuestion(
                id: questionID(kind, source, number),
                kind: kind,
                prompt: "Quel est le genre principal de « \(title) » ?",
                options: choices,
                correctAnswerIndex: correctIndex,
                imageURL: source.item.backdropURL,
                imageIsPortrait: false,
                mediaKind: source.item.kind,
                explanation: "Le genre principal de « \(title) » est \(genre)."
            )

        case .rating:
            guard let rating = source.item.rating,
                  let base = options(correct: formattedRating(rating), others: pool.compactMap(\.item.rating).map(formattedRating)) else { return nil }
            let (choices, correctIndex) = rotated(base, number: number)
            let title = source.item.title
            return QuizQuestion(
                id: questionID(kind, source, number),
                kind: kind,
                prompt: "Quelle est la note moyenne de « \(title) » sur TMDB ?",
                options: choices,
                correctAnswerIndex: correctIndex,
                imageURL: source.item.backdropURL,
                imageIsPortrait: false,
                mediaKind: source.item.kind,
                explanation: "« \(title) » est noté \(formattedRating(rating)) sur TMDB."
            )
        }
    }

    // MARK: - Utilitaires

    /// Pour les questions de personnage, privilégie un second acteur afin de
    /// varier les questions issues d'une même œuvre.
    nonisolated private static func castEntry(in source: QuizSource, excludingCharacter: Bool) -> Cast? {
        let valid = source.cast.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.character.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            $0.character != "?"
        }
        guard !valid.isEmpty else { return nil }
        return excludingCharacter && valid.count > 1 ? valid[1] : valid[0]
    }

    /// Quatre propositions distinctes : la bonne réponse et trois distracteurs.
    nonisolated private static func options(correct: String, others: [String]) -> [String]? {
        guard !normalized(correct).isEmpty else { return nil }

        var result = [correct]
        var seen: Set<String> = [normalized(correct)]

        for value in others {
            let key = normalized(value)
            guard !key.isEmpty, seen.insert(key).inserted else { continue }
            result.append(value)
            if result.count == optionCount { break }
        }

        return result.count == optionCount ? result : nil
    }

    /// Fait tourner la bonne réponse pour éviter qu'elle soit toujours en premier.
    nonisolated private static func rotated(_ base: [String], number: Int) -> ([String], Int) {
        let rotation = number % optionCount
        let choices = Array(base[rotation...]) + Array(base[..<rotation])
        return (choices, (optionCount - rotation) % optionCount)
    }

    nonisolated private static func unique(_ sources: [QuizSource]) -> [QuizSource] {
        var seen: Set<String> = []
        var result: [QuizSource] = []

        for source in sources {
            let key = normalized(source.item.title)
            guard !key.isEmpty, seen.insert(key).inserted else { continue }
            result.append(source)
        }
        return result
    }

    nonisolated private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    nonisolated private static func formattedRating(_ rating: Double) -> String {
        String(format: "%.1f / 10", rating).replacingOccurrences(of: ".", with: ",")
    }

    nonisolated private static func questionID(_ kind: QuizQuestionKind, _ source: QuizSource, _ number: Int) -> String {
        "quiz-\(number)-\(kind.rawValue)-\(source.id)"
    }
}
