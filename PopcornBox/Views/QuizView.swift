import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel: QuizViewModel

    init() {
        let client: TMDBProviding = UITesting.isEnabled ? UITesting.Client() : TMDBClient()
        _viewModel = StateObject(wrappedValue: QuizViewModel(client: client))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Préparation du quizz...")
                case .error(let message):
                    errorView(message)
                case .finished:
                    resultView
                case .ready:
                    if let question = viewModel.currentQuestion {
                        questionView(question)
                    } else {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Quiz")
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Question

    @ViewBuilder
    private func questionView(_ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Question \(viewModel.questionNumber) / \(viewModel.questions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: viewModel.progress)
                    .tint(.red)
            }
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 20) {
                    // Catégorie de la question (image, acteurs, personnages...)
                    HStack(spacing: 6) {
                        Image(systemName: symbol(for: question))
                        Text(question.kind.label)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())

                    questionImage(question)

                    Text(question.prompt)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        ForEach(question.options.indices, id: \.self) { index in
                            answerButton(index: index, question: question)
                        }
                    }

                    feedbackView

                    if viewModel.selectedAnswerIndex != nil {
                        Button(viewModel.isLastQuestion ? "Voir mon score" : "Question suivante") {
                            viewModel.next()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .accessibilityIdentifier("quiz.next")
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func answerButton(index: Int, question: QuizQuestion) -> some View {
        let isSelected = viewModel.selectedAnswerIndex == index
        let isRightAnswer = question.isCorrect(answerIndex: index)

        Button {
            viewModel.answer(index: index)
        } label: {
            HStack {
                Text(question.options[index])
                    .font(.body)
                Spacer()
                if isSelected {
                    Image(systemName: isRightAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isRightAnswer ? .green : .red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .background(answerBackground(isSelected: isSelected, isRightAnswer: isRightAnswer))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.red.opacity(0.6) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedAnswerIndex != nil)
        .accessibilityIdentifier("quiz.answer.\(index)")
    }

    private func answerBackground(isSelected: Bool, isRightAnswer: Bool) -> Color {
        guard isSelected else { return Color(.secondarySystemBackground) }
        return isRightAnswer ? Color.green.opacity(0.18) : Color.red.opacity(0.18)
    }

    /// Affiche uniquement un backdrop ou un portrait d'acteur : jamais une
    /// affiche, afin qu'aucun titre ne soit visible dans l'image.
    @ViewBuilder
    private func questionImage(_ question: QuizQuestion) -> some View {
        if let url = question.imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 180, height: 220)
                case .success(let image):
                    if question.imageIsPortrait {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 180, height: 180)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.red.opacity(0.4), lineWidth: 2))
                            .shadow(radius: 8)
                    } else {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 220)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    }
                case .failure:
                    imagePlaceholder(for: question)
                @unknown default:
                    EmptyView()
                }
            }
            .accessibilityIdentifier("quiz.image")
        } else {
            imagePlaceholder(for: question)
        }
    }

    private func imagePlaceholder(for question: QuizQuestion) -> some View {
        Image(systemName: symbol(for: question))
            .font(.system(size: 60))
            .foregroundStyle(.secondary)
            .frame(height: 220)
            .accessibilityIdentifier("quiz.image.placeholder")
    }

    private func symbol(for question: QuizQuestion) -> String {
        switch question.kind {
        case .actor, .character:
            return "person.crop.circle.fill"
        case .image, .year, .genre, .rating:
            return question.mediaKind == .movie ? "film" : "tv"
        }
    }

    // MARK: - Feedback et résultat

    @ViewBuilder
    private var feedbackView: some View {
        switch viewModel.feedback {
        case .none:
            EmptyView()
        case .correct(let explanation):
            VStack(spacing: 4) {
                Label("Bonne réponse !", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .fontWeight(.semibold)
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("quiz.feedback.correct")
        case .incorrect(let correctAnswer):
            VStack(spacing: 4) {
                Label("Réponse incorrecte", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .fontWeight(.semibold)
                Text("La bonne réponse était « \(correctAnswer) ».")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("quiz.feedback.incorrect")
        }
    }

    @ViewBuilder
    private var resultView: some View {
        VStack(spacing: 24) {
            Image(systemName: viewModel.score * 2 >= viewModel.questions.count
                  ? "trophy.fill" : "popcorn.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)

            Text("Partie terminée !")
                .font(.title)
                .fontWeight(.bold)

            Text("\(viewModel.score) / \(viewModel.questions.count)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.red)

            Text(resultMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button("Rejouer") { viewModel.restart() }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityIdentifier("quiz.replay")

                Button("Nouvelles questions") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private var resultMessage: String {
        let total = max(viewModel.questions.count, 1)
        let ratio = Double(viewModel.score) / Double(total)
        switch ratio {
        case 1: return "Score parfait : vous êtes un vrai cinéphile !"
        case 0.7...: return "Bravo, vous connaissez bien le catalogue !"
        case 0.4...: return "Pas mal ! Retentez votre chance."
        default: return "Un petit effort : rejouez pour vous améliorer !"
        }
    }

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("Impossible de charger le quizz")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Réessayer") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityIdentifier("quiz.retry")
        }
        .padding()
    }
}

#Preview {
    QuizView()
}
