import Foundation
import Network

/// Local HTTP transport — POST /mesh with JSON body; no cloud dependency.
final class LocalHTTPPresenceTransport: PresenceTransportProvider, @unchecked Sendable {
    var onMessageReceived: (@Sendable (NoxMeshMessage, String?) -> Void)?

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "dev.nox.mesh.transport")
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func startListening(port listenPort: UInt16) throws {
        stopListening()
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        guard let nwPort = NWEndpoint.Port(rawValue: listenPort) else {
            throw NoxMeshError.transportUnavailable
        }
        let listener = try NWListener(using: params, on: nwPort)
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection: connection)
        }
        listener.stateUpdateHandler = { state in
            if case .failed(let err) = state {
                NoxPresenceMeshDiagnostics.log("Listener failed: \(err.localizedDescription)")
            }
        }
        listener.start(queue: queue)
        self.listener = listener
        NoxPresenceMeshDiagnostics.log("Transport listening on port \(listenPort)")
    }

    func stopListening() {
        listener?.cancel()
        listener = nil
    }

    func send(_ message: NoxMeshMessage, to host: String, port targetPort: Int) async throws {
        let body = try encoder.encode(message)
        let hostLiteral = host.hasSuffix(".") ? String(host.dropLast()) : host
        guard let url = URL(string: "http://\(hostLiteral):\(targetPort)/mesh") else {
            throw NoxMeshError.transportUnavailable
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 8
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw NoxMeshError.transportUnavailable
        }
    }

    private func accept(connection: NWConnection) {
        connection.start(queue: queue)
        readHTTP(on: connection, accumulated: Data())
    }

    private func readHTTP(on connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 131072) { [weak self] chunk, _, isComplete, _ in
            guard let self else {
                connection.cancel()
                return
            }
            var data = accumulated
            if let chunk { data.append(chunk) }
            if let message = self.parseMeshMessage(from: data) {
                self.respondOK(on: connection)
                self.onMessageReceived?(message, nil)
                return
            }
            if isComplete || data.count > 256_000 {
                connection.cancel()
                return
            }
            self.readHTTP(on: connection, accumulated: data)
        }
    }

    private func parseMeshMessage(from data: Data) -> NoxMeshMessage? {
        guard let headerEnd = data.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let headerData = data[..<headerEnd.lowerBound]
        guard let headerText = String(data: headerData, encoding: .utf8) else { return nil }
        let contentLength = headerText
            .components(separatedBy: "\r\n")
            .first { $0.lowercased().hasPrefix("content-length:") }?
            .split(separator: ":")
            .last
            .flatMap { Int($0.trimmingCharacters(in: .whitespaces)) } ?? 0
        let bodyStart = headerEnd.upperBound
        let available = data.count - bodyStart
        if contentLength > 0, available < contentLength { return nil }
        let body: Data
        if contentLength > 0 {
            body = data[bodyStart ..< bodyStart + contentLength]
        } else {
            body = data[bodyStart...]
        }
        return try? decoder.decode(NoxMeshMessage.self, from: body)
    }

    private func respondOK(on connection: NWConnection) {
        let response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK"
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
