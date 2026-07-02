import Foundation

// MARK: - DishUseCase

struct DishUseCase: Sendable {
    let repository: any DishRepository
    let proficiency = ProficiencyUseCase()

    // MARK: Queries

    func allDishes() async throws -> [Dish] {
        try await repository.fetchAll()
    }

    func dishes(in categoryId: UUID) async throws -> [Dish] {
        try await repository.fetch(byCategory: categoryId)
    }

    func cookingRecords(for dishId: UUID) async throws -> [CookingRecord] {
        try await repository.fetchCookingRecords(for: dishId)
    }

    // MARK: Mutations

    func createDish(_ dish: Dish) async throws {
        try await repository.save(dish)
    }

    func updateDish(_ dish: Dish) async throws {
        try await repository.update(dish)
    }

    func deleteDish(id: UUID) async throws {
        try await repository.delete(id: id)
    }

    /// 记录一次烹饪打卡；返回是否触发升级 + 新等级
    func logCooking(
        _ record: CookingRecord
    ) async throws -> (didLevelUp: Bool, newLevel: ProficiencyLevel?) {
        let (newXP, didLevelUp) = try await repository.addCookingRecord(record)
        let newLevel: ProficiencyLevel? = didLevelUp ? proficiency.levelAfterLevelUp(newXP: newXP) : nil
        return (didLevelUp, newLevel)
    }
}
