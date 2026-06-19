import Foundation

/// A tournament stadium, from the Airtable `Venues` table (static reference
/// data). Names are proper nouns and are not localized.
public struct Venue: Identifiable, Hashable, Sendable {
    /// Airtable record ID.
    public let id: String
    /// Stadium name, e.g. "MetLife Stadium".
    public let name: String
    /// API-Football venue id, for cross-referencing.
    public let externalID: Int?
    public let city: String
    public let country: String
    public let capacity: Int?
    /// Playing surface, e.g. "grass".
    public let surface: String
    /// Stadium photo, when available.
    public let imageURL: URL?

    public init(
        id: String,
        name: String,
        externalID: Int?,
        city: String,
        country: String,
        capacity: Int?,
        surface: String,
        imageURL: URL?
    ) {
        self.id = id
        self.name = name
        self.externalID = externalID
        self.city = city
        self.country = country
        self.capacity = capacity
        self.surface = surface
        self.imageURL = imageURL
    }
}
