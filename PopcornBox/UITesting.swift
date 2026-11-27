import Foundation

/// Infrastructure dédiée aux tests d'interface utilisateur (UI tests).
///
/// Lorsque l'application est lancée avec l'argument de lancement `-UITesting`,
/// les vues utilisent `UITesting.Client` à la place du vrai `TMDBClient`.
/// Ainsi les tests UI sont déterministes et ne dépendent ni du réseau ni d'une
/// clé API.
enum UITesting {
    /// `true` quand l'appli est lancée avec l'argument `-UITesting`.
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }

    /// Client TMDB factice retournant des données fixes.
    final class Client: TMDBProviding {
        private let delay: UInt64 = 100_000_000 // 0,1 s pour simuler le réseau

        func suggest(mediaType: MediaType) async throws -> [FilmSerieItem] {
            try await Task.sleep(nanoseconds: delay)
            return mediaType == .movie ? Self.movies : Self.series
        }

        func search(mediaType: MediaType, query: String) async throws -> [FilmSerieItem] {
            try await Task.sleep(nanoseconds: delay)
            let q = query.lowercased()
            let all = mediaType == .movie ? Self.movies : Self.series
            return all.filter { $0.title.lowercased().contains(q) }
        }

        func fetchCast(mediaType: MediaType, id: Int) async throws -> [Cast] {
            try await Task.sleep(nanoseconds: delay)
            return Self.castByID[id] ?? []
        }

        // MARK: - Données factices

        static let movies: [FilmSerieItem] = [
            FilmSerieItem(
                id: 1,
                kind: .movie,
                title: "Inception",
                snippet: "Un voleur qui pénètre dans les rêves des autres.",
                smallPosterURL: URL(string: "https://example.com/small/1.jpg"),
                largePosterURL: URL(string: "https://example.com/poster/1.jpg"),
                url: URL(string: "https://www.themoviedb.org/movie/1"),
                backdropURL: URL(string: "https://example.com/backdrop/1.jpg"),
                releaseYear: 2010,
                genreIDs: [28, 878, 53],
                rating: 8.8
            ),
            FilmSerieItem(
                id: 2,
                kind: .movie,
                title: "Le Seigneur des anneaux",
                snippet: "Un hobbit doit détruire l'anneau unique.",
                smallPosterURL: URL(string: "https://example.com/small/2.jpg"),
                largePosterURL: URL(string: "https://example.com/poster/2.jpg"),
                url: URL(string: "https://www.themoviedb.org/movie/2"),
                backdropURL: URL(string: "https://example.com/backdrop/2.jpg"),
                releaseYear: 2001,
                genreIDs: [12, 14, 36],
                rating: 9.0
            ),
            FilmSerieItem(
                id: 3,
                kind: .movie,
                title: "Pulp Fiction",
                snippet: "Histoires croisées dans le milieu criminel.",
                smallPosterURL: URL(string: "https://example.com/small/3.jpg"),
                largePosterURL: URL(string: "https://example.com/poster/3.jpg"),
                url: URL(string: "https://www.themoviedb.org/movie/3"),
                backdropURL: URL(string: "https://example.com/backdrop/3.jpg"),
                releaseYear: 1994,
                genreIDs: [80, 35],
                rating: 8.9
            ),
        ]

        static let series: [FilmSerieItem] = [
            FilmSerieItem(
                id: 101,
                kind: .series,
                title: "Stranger Things",
                snippet: "Des enfants affrontent des phénomènes surnaturels.",
                smallPosterURL: URL(string: "https://example.com/small/101.jpg"),
                largePosterURL: URL(string: "https://example.com/poster/101.jpg"),
                url: URL(string: "https://www.themoviedb.org/tv/101"),
                backdropURL: URL(string: "https://example.com/backdrop/101.jpg"),
                releaseYear: 2016,
                genreIDs: [18, 878, 9648],
                rating: 8.7
            ),
            FilmSerieItem(
                id: 102,
                kind: .series,
                title: "Breaking Bad",
                snippet: "Un professeur de chimie devient trafiquant de drogue.",
                smallPosterURL: URL(string: "https://example.com/small/102.jpg"),
                largePosterURL: URL(string: "https://example.com/poster/102.jpg"),
                url: URL(string: "https://www.themoviedb.org/tv/102"),
                backdropURL: URL(string: "https://example.com/backdrop/102.jpg"),
                releaseYear: 2008,
                genreIDs: [18, 80, 35],
                rating: 9.5
            ),
        ]

        static let castByID: [Int: [Cast]] = [
            1: [
                Cast(id: 101, name: "Leonardo DiCaprio", character: "Dom Cobb", profilePath: "/p/1.jpg"),
                Cast(id: 102, name: "Elliot Page", character: "Ariadne", profilePath: "/p/2.jpg"),
            ],
            2: [
                Cast(id: 201, name: "Elijah Wood", character: "Frodon Sacquet", profilePath: "/p/3.jpg"),
                Cast(id: 202, name: "Ian McKellen", character: "Gandalf", profilePath: "/p/4.jpg"),
            ],
            3: [
                Cast(id: 301, name: "John Travolta", character: "Vincent Vega", profilePath: "/p/5.jpg"),
                Cast(id: 302, name: "Uma Thurman", character: "Mia Wallace", profilePath: "/p/6.jpg"),
            ],
            101: [
                Cast(id: 401, name: "Millie Bobby Brown", character: "Onze", profilePath: "/p/7.jpg"),
                Cast(id: 402, name: "Finn Wolfhard", character: "Mike Wheeler", profilePath: "/p/8.jpg"),
            ],
            102: [
                Cast(id: 501, name: "Bryan Cranston", character: "Walter White", profilePath: "/p/9.jpg"),
                Cast(id: 502, name: "Aaron Paul", character: "Jesse Pinkman", profilePath: "/p/10.jpg"),
            ],
        ]
    }
}
