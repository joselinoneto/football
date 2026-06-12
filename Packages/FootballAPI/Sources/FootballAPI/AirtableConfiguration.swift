import Foundation

public struct AirtableConfiguration: Sendable {
    public let baseID: String
    public let token: String
    public let baseURL: URL

    public init(
        baseID: String,
        token: String,
        baseURL: URL = URL(string: "https://api.airtable.com/v0")!
    ) {
        self.baseID = baseID
        self.token = token
        self.baseURL = baseURL
    }
}
