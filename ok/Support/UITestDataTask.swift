#if DEBUG
import Foundation

/// Données locales utilisées uniquement par les tests d'interface.
/// Elles évitent de dépendre du réseau et du quota de l'API TMDB pendant les tests.
enum UITestDataTask {
    static let launchArgument = "--uitests-mock"
    static let emptyArgument = "--uitests-empty"
    static let errorArgument = "--uitests-error"

    private static let movies = """
    {"results":[{"id":101,"title":"Film UI Test","overview":"Un synopsis de test","poster_path":null},{"id":102,"title":"Film sans synopsis","overview":"","poster_path":null}]}
    """

    private static let series = """
    {"results":[{"id":201,"name":"Série UI Test","overview":"Un synopsis de test","poster_path":null}]}
    """

    private static let cast = """
    {"cast":[{"id":1,"name":"Acteur UI Test","character":"Rôle de test","profile_path":null}]}
    """

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
                json = cast
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
