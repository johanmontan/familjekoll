import Foundation

struct SheetAPIClient: Sendable {
    enum ClientError: LocalizedError {
        case notConfigured
        case invalidEndpoint
        case invalidResponse
        case server(statusCode: Int)
        case api(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                "Google Sheets är inte anslutet ännu."
            case .invalidEndpoint:
                "Webbadressen till Google Apps Script är ogiltig."
            case .invalidResponse:
                "Google Apps Script skickade ett svar som appen inte kunde läsa."
            case .server(let statusCode):
                "Google Apps Script svarade med felkod \(statusCode)."
            case .api(let message):
                message
            }
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchEvents(from startDate: Date, through endDate: Date) async throws -> [FamilyEvent] {
        guard let endpoint = AppConfiguration.endpointURL else {
            throw ClientError.notConfigured
        }

        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw ClientError.invalidEndpoint
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { ["from", "to"].contains($0.name) }
        queryItems.append(URLQueryItem(name: "from", value: LocalDay.string(from: startDate)))
        queryItems.append(URLQueryItem(name: "to", value: LocalDay.string(from: endDate)))
        components.queryItems = queryItems

        guard let url = components.url else {
            throw ClientError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ClientError.server(statusCode: httpResponse.statusCode)
        }

        do {
            let response = try JSONDecoder().decode(SheetResponse.self, from: data)
            if let message = response.error, !message.isEmpty {
                throw ClientError.api(message)
            }
            return response.events.filter { !$0.normalizedTitle.isEmpty }
        } catch let error as ClientError {
            throw error
        } catch {
            throw ClientError.invalidResponse
        }
    }
}
