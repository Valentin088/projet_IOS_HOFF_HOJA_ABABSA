import Foundation

/// Abstraction du client TMDB : permet d'injecter un faux client dans les tests
/// sans dépendre du réseau.
protocol TMDBProviding {
    func suggest(mediaType: MediaType) async throws -> [FilmSerieItem]
    func search(mediaType: MediaType, query: String) async throws -> [FilmSerieItem]
    func fetchCast(mediaType: MediaType, id: Int) async throws -> [Cast]
}
