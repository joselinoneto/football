import SwiftData
import FootballCore

@Model
public final class StoredTeam {
    @Attribute(.unique) public var remoteID: String
    public var name: String
    public var code: String
    public var groupName: String
    public var flag: String

    public init(remoteID: String, name: String, code: String, groupName: String, flag: String) {
        self.remoteID = remoteID
        self.name = name
        self.code = code
        self.groupName = groupName
        self.flag = flag
    }
}

extension StoredTeam {
    convenience init(_ team: Team) {
        self.init(remoteID: team.id, name: team.name, code: team.code, groupName: team.group, flag: team.flag)
    }

    func update(from team: Team) {
        name = team.name
        code = team.code
        groupName = team.group
        flag = team.flag
    }

    var team: Team {
        Team(id: remoteID, name: name, code: code, group: groupName, flag: flag)
    }
}
