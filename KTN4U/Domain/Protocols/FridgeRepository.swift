import Foundation

// MARK: - FridgeRepository

protocol FridgeRepository: Sendable {
    func fetchAll() async throws -> [FridgeItem]
    func save(_ item: FridgeItem) async throws
    func update(_ item: FridgeItem) async throws
    func delete(id: UUID) async throws
}
