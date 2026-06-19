import Foundation
import SwiftData
import FootballCore

@Model
public final class StoredSquadMember {
    @Attribute(.unique) public var remoteID: String
    public var teamID: String?
    public var player: String
    public var number: Int?
    public var positionRaw: String?
    public var age: Int?
    public var photoURL: URL?

    public init(
        remoteID: String,
        teamID: String?,
        player: String,
        number: Int?,
        positionRaw: String?,
        age: Int?,
        photoURL: URL?
    ) {
        self.remoteID = remoteID
        self.teamID = teamID
        self.player = player
        self.number = number
        self.positionRaw = positionRaw
        self.age = age
        self.photoURL = photoURL
    }
}

extension StoredSquadMember {
    convenience init(_ m: SquadMember) {
        self.init(
            remoteID: m.id, teamID: m.teamID, player: m.player, number: m.number,
            positionRaw: m.position?.rawValue, age: m.age, photoURL: m.photoURL
        )
    }

    func update(from m: SquadMember) {
        teamID = m.teamID
        player = m.player
        number = m.number
        positionRaw = m.position?.rawValue
        age = m.age
        photoURL = m.photoURL
    }

    var squadMember: SquadMember {
        SquadMember(
            id: remoteID, teamID: teamID, player: player, number: number,
            position: positionRaw.flatMap(PlayerPosition.init(rawValue:)),
            age: age, photoURL: photoURL
        )
    }
}
