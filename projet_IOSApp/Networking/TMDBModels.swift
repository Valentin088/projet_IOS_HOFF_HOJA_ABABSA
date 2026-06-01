import Foundation

struct TMDBPopularResponse<T: Decodable>: Decodable {
    let results: [T]
}

struct TMDBMovie: Decodable {
    let id: Int
    let title: String?
    let overview: String?

    // For completeness (not used in current UI)
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
    }
}

struct TMDBTV: Decodable {
    let id: Int
    let name: String?
    let overview: String?

    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
    }
}

