import Foundation

// MARK: - DishRepository

/// 菜品数据源协议（由 Data 层的 SwiftData 实现）
protocol DishRepository: Sendable {
    func fetchAll() async throws -> [Dish]
    func fetch(byCategory categoryId: UUID) async throws -> [Dish]
    func fetch(byId id: UUID) async throws -> Dish?

    func save(_ dish: Dish) async throws
    func update(_ dish: Dish) async throws
    func delete(id: UUID) async throws

    /// 添加烹饪记录，自动更新菜品 XP；返回新 XP 与是否升级
    func addCookingRecord(_ record: CookingRecord) async throws -> (newXP: Int, didLevelUp: Bool)

    func fetchCookingRecords(for dishId: UUID) async throws -> [CookingRecord]
}
