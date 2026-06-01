import SwiftUI

struct SeriesView: View {
    @StateObject private var vm = BoxOfficeViewModel(mediaType: .series)

    var body: some View {
        Group {
            switch vm.state {
            case .idle, .loading:
                ProgressView("Chargement...")
                    .task {
                        if vm.state == .idle {
                            await vm.load()
                        }
                    }
            case .error(let message):
                VStack(spacing: 12) {
                    Text("Erreur")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Réessayer") {
                        Task { await vm.load(force: true) }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                List {
                    ForEach(vm.items) { item in
                        NavigationLink(value: item) {
                            FilmSerieItemView(item: item)
                        }
                    }
                }
                .navigationTitle("Séries")
            }
        }
        .navigationDestination(for: FilmSerieItem.self) { item in
            DetailsView(item: item)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await vm.load(force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(vm.state == .loading)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SeriesView()
    }
}

