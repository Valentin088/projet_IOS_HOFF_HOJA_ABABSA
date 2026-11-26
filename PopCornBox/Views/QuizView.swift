import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel = QuizViewModel()

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
        .accessibilityIdentifier("quiz.root")
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Question

    @ViewBuilder
    private func questionView(_ question: QuizQuestion) -> some View {
        ScrollView {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text("Question \(viewModel.questionNumber) / \(viewModel.questions.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(value: viewModel.progress)
                        .tint(.red)
                }

                HStack(spacing: 4) {
                    Image(systemName: symbol(for: question))
                    Text(question.kind.label)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.12))
                .clipShape(Capsule())

                questionImage(question)

                Text(question.prompt)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                VStack(spacing: 6) {
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
            .padding(.vertical)
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
                    .font(.caption)
                    .lineLimit(2)
                Spacer()
                if isSelected {
                    Image(systemName: isRightAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isRightAnswer ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 8)
            .background(answerBackground(isSelected: isSelected, isRightAnswer: isRightAnswer))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedAnswerIndex != nil)
        .accessibilityIdentifier("quiz.answer.\(index)")
    }

    private func answerBackground(isSelected: Bool, isRightAnswer: Bool) -> Color {
        guard isSelected else { return Color.gray.opacity(0.18) }
        return isRightAnswer ? Color.green.opacity(0.22) : Color.red.opacity(0.22)
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
                        .frame(width: 110, height: question.imageIsPortrait ? 110 : 80)
                case .success(let image):
                    if question.imageIsPortrait {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.red.opacity(0.4), lineWidth: 2))
                    } else {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            .font(.system(size: 36))
            .foregroundStyle(.secondary)
            .frame(height: 90)
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
            VStack(spacing: 2) {
                Label("Bonne réponse !", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption.weight(.semibold))
                Text(explanation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("quiz.feedback.correct")
        case .incorrect(let correctAnswer):
            VStack(spacing: 2) {
                Label("Réponse incorrecte", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption.weight(.semibold))
                Text("La bonne réponse était « \(correctAnswer) ».")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("quiz.feedback.incorrect")
        }
    }

    @ViewBuilder
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: viewModel.score * 2 >= viewModel.questions.count
                      ? "trophy.fill" : "popcorn.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.red)

                Text("Partie terminée !")
                    .font(.headline)

                Text("\(viewModel.score) / \(viewModel.questions.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)

                Text(resultMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Rejouer") { viewModel.restart() }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityIdentifier("quiz.replay")

                Button("Nouvelles questions") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
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
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("Impossible de charger le quizz")
                .font(.headline)
            Text(message)
                .font(.caption)
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
