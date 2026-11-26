import Foundation
import Combine
import SwiftUI

class TMDBClient: ObservableObject, TMDBProviding {
    private let bearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxMWI2MTg5Y2NhMjk4YTNiOTU4YzJjODA0ZmI5NDI5YSIsIm5iZiI6MTc4MDMwNTcxOC41MTYsInN1YiI6IjZhMWQ0ZjM2MzA0N2YyNDcyZTRhZDJjNCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.YjG-DYoizz1MCUCI2fQFbkdlK_dBoTGtKu4yHrcXpKU"
    
    private func fetch<T: Decodable>(urlStr: String) async throws -> T {
        let url = URL(string: urlStr)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Bearer \(bearerToken)"
        ]
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Mapping

    private func filmSerieItem(movie: Movie) -> FilmSerieItem {
        FilmSerieItem(
            id: movie.id,
            kind: .movie,
            title: movie.title,
            snippet: movie.overview,
            smallPosterURL: movie.smallPosterURL,
            largePosterURL: movie.largePosterURL,
            url: URL(string: "https://www.themoviedb.org/movie/\(movie.id)"),
            backdropURL: movie.backdropURL,
            releaseYear: movie.releaseYear,
            genreIDs: movie.genreIDs,
            rating: movie.voteAverage
        )
    }

    private func filmSerieItem(show: TVShow) -> FilmSerieItem {
        FilmSerieItem(
            id: show.id,
            kind: .series,
            title: show.name,
            snippet: show.overview,
            smallPosterURL: show.smallPosterURL,
            largePosterURL: show.largePosterURL,
            url: URL(string: "https://www.themoviedb.org/tv/\(show.id)"),
            backdropURL: show.backdropURL,
            releaseYear: show.releaseYear,
            genreIDs: show.genreIDs,
            rating: show.voteAverage
        )
    }
    
    // MARK: - Méthodes unifiées requises par le ViewModel
    
    func suggest(mediaType: MediaType) async throws -> [FilmSerieItem] {
        switch mediaType {
        case .movie:
            let response: TMDBResponse<Movie> = try await fetch(urlStr: "https://api.themoviedb.org/3/movie/popular?language=fr-FR&page=1")
            return response.results.map(filmSerieItem(movie:))
        case .series:
            let response: TMDBResponse<TVShow> = try await fetch(urlStr: "https://api.themoviedb.org/3/tv/popular?language=fr-FR&page=1")
            return response.results.map(filmSerieItem(show:))
        }
    }
    
    func search(mediaType: MediaType, query: String) async throws -> [FilmSerieItem] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        
        switch mediaType {
        case .movie:
            let urlStr = "https://api.themoviedb.org/3/search/movie?language=fr-FR&query=\(encodedQuery)&page=1"
            let response: TMDBResponse<Movie> = try await fetch(urlStr: urlStr)
            return response.results.map(filmSerieItem(movie:))
        case .series:
            let urlStr = "https://api.themoviedb.org/3/search/tv?language=fr-FR&query=\(encodedQuery)&page=1"
            let response: TMDBResponse<TVShow> = try await fetch(urlStr: urlStr)
            return response.results.map(filmSerieItem(show:))
        }
    }
    
    func fetchCast(mediaType: MediaType, id: Int) async throws -> [Cast] {
        switch mediaType {
        case .movie:
            let response: CreditsResponse = try await fetch(urlStr: "https://api.themoviedb.org/3/movie/\(id)/credits")
            return response.cast
        case .series:
            let response: CreditsResponse = try await fetch(urlStr: "https://api.themoviedb.org/3/tv/\(id)/credits")
            return response.cast
        }
    }
}
