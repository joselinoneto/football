import Foundation

struct AirtablePage<Fields: Decodable & Sendable>: Decodable, Sendable {
    let records: [AirtableRecord<Fields>]
    let offset: String?
}

struct AirtableRecord<Fields: Decodable & Sendable>: Decodable, Sendable {
    let id: String
    let fields: Fields
}

/// Minimal Airtable Web API transport: bearer auth, page-size 100, follows
/// the `offset` cursor until the table is exhausted.
struct AirtableTransport: Sendable {
    let configuration: AirtableConfiguration
    let session: URLSession

    func allRecords<Fields: Decodable & Sendable>(
        table: String,
        fields: [String],
        filterByFormula: String? = nil
    ) async throws -> [AirtableRecord<Fields>] {
        var records: [AirtableRecord<Fields>] = []
        var offset: String? = nil
        repeat {
            let page: AirtablePage<Fields> = try await page(
                table: table, fields: fields, filterByFormula: filterByFormula, offset: offset
            )
            records.append(contentsOf: page.records)
            offset = page.offset
        } while offset != nil
        return records
    }

    private func page<Fields: Decodable & Sendable>(
        table: String,
        fields: [String],
        filterByFormula: String?,
        offset: String?
    ) async throws -> AirtablePage<Fields> {
        let tableURL = configuration.baseURL
            .appending(path: configuration.baseID)
            .appending(path: table)
        var components = URLComponents(url: tableURL, resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem(name: "pageSize", value: "100")]
        queryItems.append(contentsOf: fields.map { URLQueryItem(name: "fields[]", value: $0) })
        if let filterByFormula {
            queryItems.append(URLQueryItem(name: "filterByFormula", value: filterByFormula))
        }
        if let offset {
            queryItems.append(URLQueryItem(name: "offset", value: offset))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { throw AirtableError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(configuration.token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AirtableError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw AirtableError.httpFailure(statusCode: http.statusCode)
        }
        return try Self.decoder.decode(AirtablePage<Fields>.self, from: data)
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            // Airtable emits "2026-06-17T04:00:00.000Z"; be lenient about
            // the fractional part.
            if let date = try? Date(string, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
                return date
            }
            if let date = try? Date(string, strategy: Date.ISO8601FormatStyle()) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date format: \(string)"
            )
        }
        return decoder
    }
}
