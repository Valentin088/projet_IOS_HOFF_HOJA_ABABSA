import SwiftUI

/// Vue de l'historique des quiz récents de l'utilisateur.
struct QuizHistoryView: View {
    @StateObject private var dataViewModel = UserDataViewModel()
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement de l'historique...")
                } else if dataViewModel.recentQuizEntries.isEmpty {
                    ContentUnavailableView(
                        "Aucun quiz effectué",
                        systemImage: "questionmark.circle",
                        description: Text("Jouez à un quiz pour voir votre historique ici.")
                    )
                } else {
                    List {
                        ForEach(dataViewModel.recentQuizEntries) { entry in
                            QuizHistoryRow(entry: entry)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Historique des Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await dataViewModel.loadUserData()
                isLoading = false
            }
        }
    }
}

/// Ligne d'une entrée d'historique de quiz.
private struct QuizHistoryRow: View {
    let entry: QuizHistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.scoreColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text("\(entry.score)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(entry.scoreColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Quiz « \(entry.quizId) »")
                    .font(.headline)
                    .lineLimit(1)

                Text("\(entry.score) / \(entry.total)  •  \(Int(entry.percentage)) %")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.completedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

extension QuizHistoryEntry {
    var scoreColor: Color {
        let ratio = Double(score) / Double(max(total, 1))
        switch ratio {
        case 1: return .green
        case 0.7...: return .blue
        case 0.4...: return .orange
        default: return .red
        }
    }
}

#Preview {
    QuizHistoryView()
}
