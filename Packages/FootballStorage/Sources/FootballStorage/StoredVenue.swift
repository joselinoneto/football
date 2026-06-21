import Foundation
import SwiftData
import FootballCore

@Model
public final class StoredVenue {
    @Attribute(.unique) public var remoteID: String
    public var name: String
    public var externalID: Int?
    public var city: String
    public var country: String
    public var capacity: Int?
    public var surface: String
    public var imageURL: URL?

    public init(
        remoteID: String,
        name: String,
        externalID: Int?,
        city: String,
        country: String,
        capacity: Int?,
        surface: String,
        imageURL: URL?
    ) {
        self.remoteID = remoteID
        self.name = name
        self.externalID = externalID
        self.city = city
        self.country = country
        self.capacity = capacity
        self.surface = surface
        self.imageURL = imageURL
    }
}

extension StoredVenue {
    convenience init(_ v: Venue) {
        self.init(
            remoteID: v.id, name: v.name, externalID: v.externalID, city: v.city,
            country: v.country, capacity: v.capacity, surface: v.surface, imageURL: v.imageURL
        )
    }

    func update(from v: Venue) {
        name = v.name
        externalID = v.externalID
        city = v.city
        country = v.country
        capacity = v.capacity
        surface = v.surface
        imageURL = v.imageURL
    }

    var venue: Venue {
        Venue(
            id: remoteID, name: name, externalID: externalID, city: city,
            country: country, capacity: capacity, surface: surface, imageURL: imageURL
        )
    }
}
