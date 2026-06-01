import Foundation

struct DuckDuckGoSearchResponse: Decodable {
    let RelatedTopics: [RelatedTopic]?

    struct RelatedTopic: Decodable {
        let Text: String?
        let FirstURL: String?
        let Topics: [RelatedTopic]?
    }
}

