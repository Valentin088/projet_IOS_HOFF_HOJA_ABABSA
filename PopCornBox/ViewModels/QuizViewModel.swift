import Foundation
import Combine

/// Retour affiché après une réponse.
enum QuizFeedback: Equatable {
    case none
    case correct(String)
    case incorrect(correctAnswer: String)
}

@MainActor
final class QuizViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case finished
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var questions: [QuizQuestion] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var selectedAnswerIndex: Int?
    @Published private(set) var score = 0

    private let client: TMDBProviding
    private let questionCount: Int
    private let sourceCount: Int

    init(
        client: TMDBProviding? = nil,
        questionCount: Int = QuizGenerator.defaultQuestionCount,
        sourceCount: Int = QuizGenerator.defaultSourceCount
    ) {
        self.client = client ?? TMDBClient()
        self.questionCount = questionCount
        self.sourceCount = sourceCount
    }

    // MARK: - État dérivé

    var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var questionNumber: Int { currentIndex + 1 }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(min(currentIndex + 1, questions.count)) / Double(questions.count)
    }

    var isLastQuestion: Bool { currentIndex >= questions.count - 1 }

    var feedback: QuizFeedback {
        guard let selectedAnswerIndex, let question = currentQuestion else { return .none }
        if question.isCorrect(answerIndex: selectedAnswerIndex) {
            return .correct(question.explanation)
        }
        return .incorrect(correctAnswer: question.correctAnswer ?? "")
    }

    // MARK: - Actions

    /// Récupère films, séries et castings puis construit les questions.
    func load() async {
        state = .loading
        questions = []
        resetProgress()

        do {
            let movies = try await client.suggest(mediaType: .movie)
            let series = try await client.suggest(mediaType: .series)
            let merged = QuizGenerator.merge(movies: movies, series: series)

            var sources: [QuizSource] = []
            for item in merged.prefix(sourceCount) {
                // Un casting indisponible n'empêche pas les autres questions.
                let cast = (try? await client.fetchCast(mediaType: item.kind, id: item.id)) ?? []
                sources.append(QuizSource(item: item, cast: cast))
            }

            let generated = QuizGenerator.makeQuestions(from: sources, count: questionCount)

            guard !generated.isEmpty else {
                state = .error("Pas assez d'informations sur les films et séries pour lancer le quizz.")
                return
            }

            questions = generated
            state = .ready
        } catch {
            state = .error(TMDBError.message(for: error))
        }
    }

    /// Enregistre une réponse. Ignorée si la question est déjà répondue.
    func answer(index: Int) {
        guard state == .ready,
              selectedAnswerIndex == nil,
              let question = currentQuestion,
              question.options.indices.contains(index) else { return }

        selectedAnswerIndex = index
        if question.isCorrect(answerIndex: index) { score += 1 }
    }

    /// Passe à la question suivante ou termine la partie.
    func next() {
        guard state == .ready, selectedAnswerIndex != nil else { return }

        if isLastQuestion {
            state = .finished
        } else {
            currentIndex += 1
            selectedAnswerIndex = nil
        }
    }

    /// Rejoue une partie avec les mêmes questions.
    func restart() {
        resetProgress()
        state = questions.isEmpty ? .idle : .ready
    }

    private func resetProgress() {
        currentIndex = 0
        selectedAnswerIndex = nil
        score = 0
    }
}
