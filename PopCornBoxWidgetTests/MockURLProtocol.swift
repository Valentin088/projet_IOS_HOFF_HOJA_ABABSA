import Foundation

/// Boîte thread-safe pour remplacer la réponse réseau pendant chaque test.
final class MockResponseBox {
    private let lock = NSLock()
    private var storedHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedHandler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedHandler = newValue
        }
    }
}

/// Intercepte toutes les requêtes `URLSession` du client testé.
final class MockURLProtocol: URLProtocol {
    static var box: MockResponseBox?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.box?.handler else {
            client?.urlProtocol(
                self,
                didFailWithError: NSError(domain: "MockURLProtocol", code: 1, userInfo: nil)
            )
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
