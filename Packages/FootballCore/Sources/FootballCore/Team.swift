public struct Team: Identifiable, Hashable, Sendable {
    /// Airtable record ID, e.g. "rec2EdEkFBCdYwk3N".
    public let id: String
    public let name: String
    /// FIFA three-letter code, e.g. "BRA".
    public let code: String
    /// Group letter A–L.
    public let group: String
    /// Flag emoji, rendered as-is.
    public let flag: String

    public init(id: String, name: String, code: String, group: String, flag: String) {
        self.id = id
        self.name = name
        self.code = code
        self.group = group
        self.flag = flag
    }
}
