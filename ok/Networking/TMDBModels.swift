import Foundation

// Modèles de décodage TMDB pour l'API
struct TMDBResponse<T: Decodable>: Decodable {
    let results: [T]
}

struct Movie: Decodable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    
    var smallPosterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w154\(path)")
    }

    var largePosterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
    }
}

struct TVShow: Decodable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    
    var smallPosterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w154\(path)")
    }

    var largePosterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case posterPath = "poster_path"
    }
}



struct CreditsResponse: Decodable {
    let cast: [Cast]
}

struct Cast: Decodable, Identifiable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?

    var profileURL: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w200\(path)")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case character
        case profilePath = "profile_path"
    }
}
