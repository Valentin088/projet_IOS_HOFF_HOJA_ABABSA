#if DEBUG
import Foundation

/// Données locales utilisées uniquement par les tests d'interface.
/// Elles évitent de dépendre du réseau et du quota de l'API TMDB pendant les tests.
enum UITestDataTask {
    static let launchArgument = "--uitests-mock"
    static let emptyArgument = "--uitests-empty"
    static let errorArgument = "--uitests-error"

    private static let movies = """
    {"results":[
      {"id":101,"title":"Film UI Test","overview":"Un synopsis de test","poster_path":null,"backdrop_path":"/b101.jpg","release_date":"2024-01-01","genre_ids":[28],"vote_average":7.2},
      {"id":102,"title":"Film sans synopsis","overview":"","poster_path":null,"backdrop_path":"/b102.jpg","release_date":"2023-01-01","genre_ids":[35],"vote_average":6.4},
      {"id":103,"title":"Film UI Test 3","overview":"Synopsis 3","poster_path":null,"backdrop_path":"/b103.jpg","release_date":"2022-01-01","genre_ids":[18],"vote_average":8.1},
      {"id":104,"title":"Film UI Test 4","overview":"Synopsis 4","poster_path":null,"backdrop_path":"/b104.jpg","release_date":"2021-01-01","genre_ids":[878],"vote_average":5.9}
    ]}
    """

    private static let series = """
    {"results":[
      {"id":201,"name":"Série UI Test","overview":"Un synopsis de test","poster_path":null,"backdrop_path":"/b201.jpg","first_air_date":"2020-01-01","genre_ids":[53],"vote_average":7.8},
      {"id":202,"name":"Série UI Test 2","overview":"Synopsis 2","poster_path":null,"backdrop_path":"/b202.jpg","first_air_date":"2019-01-01","genre_ids":[12],"vote_average":6.7},
      {"id":203,"name":"Série UI Test 3","overview":"Synopsis 3","poster_path":null,"backdrop_path":"/b203.jpg","first_air_date":"2018-01-01","genre_ids":[16],"vote_average":8.5},
      {"id":204,"name":"Série UI Test 4","overview":"Synopsis 4","poster_path":null,"backdrop_path":"/b204.jpg","first_air_date":"2017-01-01","genre_ids":[14],"vote_average":7.1}
    ]}
    """

    private static func castJSON(for id: String) -> String {
        // Les écrans de détail des fixtures historiques attendent exactement ces libellés.
        return """
        {"cast":[
          {"id":\(Int(id) ?? 1),"name":"Acteur UI Test","character":"Rôle de test","profile_path":null},
          {"id":\((Int(id) ?? 1) + 1),"name":"Acteur UI Test B","character":"Rôle de test B","profile_path":null}
        ]}
        """
    }

    private static let empty = """
    {"results":[]}
    """

    private static let error = """
    {"status_code":500,"status_message":"Erreur simulée"}
    """

    static func make() -> TMDBDataTask {
        { request in
            let arguments = ProcessInfo.processInfo.arguments
            let statusCode = arguments.contains(errorArgument) ? 500 : 200
            let path = request.url?.path ?? ""

            let json: String
            if statusCode == 500 {
                json = error
            } else if arguments.contains(emptyArgument) {
                json = empty
            } else if path.contains("/credits") {
                let components = path.split(separator: "/")
                let id = components.count >= 2 ? String(components[components.count - 2]) : "1"
                json = castJSON(for: id)
            } else if path.contains("/tv/") {
                json = series
            } else {
                json = movies
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data(json.utf8), response)
        }
    }
}
#endif
