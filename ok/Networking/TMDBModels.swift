import Foundation

// Modèles de décodage TMDB pour l'API

struct TMDBResponse<T: Decodable>: Decodable {
    let results: [T]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        results = try container.decodeIfPresent([T].self, forKey: .results) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case results
    }
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case posterPath = "poster_path"
    }
}

struct CreditsResponse: Decodable {
    let cast: [Cast]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cast = try container.decodeIfPresent([Cast].self, forKey: .cast) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case cast
    }
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        character = try container.decodeIfPresent(String.self, forKey: .character) ?? ""
        profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case character
        case profilePath = "profile_path"
    }
}
