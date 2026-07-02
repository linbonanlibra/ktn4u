import Foundation
import SwiftData

// MARK: - SDDishRepository

/// 菜品数据源的 SwiftData 实现
@MainActor
final class SDDishRepository: DishRepository {
    private let context: ModelContext
    private let proficiency = ProficiencyUseCase()

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Queries

    func fetchAll() async throws -> [Dish] {
        let descriptor = FetchDescriptor<DishModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(byCategory categoryId: UUID) async throws -> [Dish] {
        let descriptor = FetchDescriptor<DishModel>(
            predicate: #Predicate { $0.categoryId == categoryId },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(byId id: UUID) async throws -> Dish? {
        let descriptor = FetchDescriptor<DishModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.toDomain()
    }

    // MARK: Mutations

    func save(_ dish: Dish) async throws {
        let model = DishModel.from(dish)
        context.insert(model)
        try context.save()
    }

    func update(_ dish: Dish) async throws {
        let dishId = dish.id          // #Predicate 不允许访问捕获 struct 的属性，提前解构为 UUID
        let descriptor = FetchDescriptor<DishModel>(
            predicate: #Predicate { $0.id == dishId }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        model.update(from: dish)
        try context.save()
    }

    func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<DishModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        context.delete(model)
        try context.save()
    }

    // MARK: Cooking Records

    func addCookingRecord(_ record: CookingRecord) async throws -> (newXP: Int, didLevelUp: Bool) {
        let dishId = record.dishId    // 同上，#Predicate 需要捕获纯 UUID，不能访问 struct 属性
        let dishDescriptor = FetchDescriptor<DishModel>(
            predicate: #Predicate { $0.id == dishId }
        )
        guard let dishModel = try context.fetch(dishDescriptor).first else {
            throw RepositoryError.notFound
        }

        let isFirstEver = dishModel.cookingRecords.isEmpty
        let oldXP = dishModel.xp
        let newXP = proficiency.newXP(currentXP: oldXP, for: record, isFirstEver: isFirstEver)
        let leveledUp = proficiency.didLevelUp(from: oldXP, to: newXP)

        let recordModel = CookingRecordModel(
            id: record.id,
            dishId: record.dishId,
            date: record.date,
            photoFilenames: record.photoFilenames,
            note: record.note,
            xpEarned: record.xpEarned
        )
        recordModel.dish = dishModel
        dishModel.cookingRecords.append(recordModel)
        dishModel.xp = newXP

        context.insert(recordModel)
        try context.save()

        return (newXP, leveledUp)
    }

    func fetchCookingRecords(for dishId: UUID) async throws -> [CookingRecord] {
        let descriptor = FetchDescriptor<CookingRecordModel>(
            predicate: #Predicate { $0.dishId == dishId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }
}

// MARK: - RepositoryError

enum RepositoryError: Error, LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound: return "数据不存在"
        }
    }
}
