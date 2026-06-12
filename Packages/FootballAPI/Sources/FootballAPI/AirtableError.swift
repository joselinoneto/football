import Foundation

public enum AirtableError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpFailure(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The Airtable request URL could not be built."
        case .invalidResponse:
            "Airtable returned an unexpected response."
        case .httpFailure(let statusCode):
            "Airtable request failed with HTTP status \(statusCode)."
        }
    }
}
