import Foundation
import SwiftData

// MARK: - SDFridgeRepository

@MainActor
final class SDFridgeRepository: FridgeRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [FridgeItem] {
        let descriptor = FetchDescriptor<FridgeItemModel>(
            sortBy: [SortDescriptor(\.expiryDate)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func save(_ item: FridgeItem) async throws {
        context.insert(FridgeItemModel.from(item))
        try context.save()
    }

    func update(_ item: FridgeItem) async throws {
        let itemId = item.id
        let descriptor = FetchDescriptor<FridgeItemModel>(
            predicate: #Predicate { $0.id == itemId }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        model.update(from: item)
        try context.save()
    }

    func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<FridgeItemModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        context.delete(model)
        try context.save()
    }
}
