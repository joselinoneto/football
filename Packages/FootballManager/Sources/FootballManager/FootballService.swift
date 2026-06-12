import FootballCore

/// What the UI layer talks to. Reads come from the local store; `refresh()`
/// pulls from the network and updates the store.
public protocol FootballService: Sendable {
    func refresh() async throws
    func teams() async throws -> [Team]
    func matches() async throws -> [Match]
}
