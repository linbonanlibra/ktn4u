import Foundation

// MARK: - CategoryRepository

protocol CategoryRepository: Sendable {
    func fetchAll() async throws -> [DishCategory]
    func fetchTopLevel() async throws -> [DishCategory]
    func fetchChildren(of parentId: UUID) async throws -> [DishCategory]
    func fetch(byId id: UUID) async throws -> DishCategory?

    func save(_ category: DishCategory) async throws
    func update(_ category: DishCategory) async throws

    /// 删除分类；若有子菜品，将其 categoryId 改为 targetId（nil = "未分类"占位 ID）
    func delete(id: UUID, movingDishesTo targetId: UUID?) async throws

    /// 批量更新同级分类的 ordinal（拖动排序后调用）
    func updateOrdinals(_ ordinals: [(id: UUID, ordinal: Int)]) async throws
}
