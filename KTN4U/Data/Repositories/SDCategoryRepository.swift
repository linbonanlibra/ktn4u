import Foundation
import SwiftData

// MARK: - SDCategoryRepository

@MainActor
final class SDCategoryRepository: CategoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [DishCategory] {
        let descriptor = FetchDescriptor<DishCategoryModel>(
            sortBy: [SortDescriptor(\.ordinal)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetchTopLevel() async throws -> [DishCategory] {
        // parentId == nil 代表顶级；SwiftData #Predicate 不支持直接判断 Optional==nil，用辅助方法
        let all = try await fetchAll()
        return all.filter { $0.isTopLevel }.sorted { $0.ordinal < $1.ordinal }
    }

    func fetchChildren(of parentId: UUID) async throws -> [DishCategory] {
        let all = try await fetchAll()
        return all.filter { $0.parentId == parentId }.sorted { $0.ordinal < $1.ordinal }
    }

    func fetch(byId id: UUID) async throws -> DishCategory? {
        let descriptor = FetchDescriptor<DishCategoryModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.toDomain()
    }

    func save(_ category: DishCategory) async throws {
        context.insert(DishCategoryModel.from(category))
        try context.save()
    }

    func update(_ category: DishCategory) async throws {
        let categoryId = category.id
        let descriptor = FetchDescriptor<DishCategoryModel>(
            predicate: #Predicate { $0.id == categoryId }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        model.update(from: category)
        try context.save()
    }

    func delete(id: UUID, movingDishesTo targetId: UUID?) async throws {
        // 1. 将该分类下的所有菜品移到目标分类
        let dishDescriptor = FetchDescriptor<DishModel>(
            predicate: #Predicate { $0.categoryId == id }
        )
        let dishes = try context.fetch(dishDescriptor)
        let fallbackId = targetId ?? UUID() // 若无目标，用「未分类」占位 UUID（Phase 5 完善）
        dishes.forEach { $0.categoryId = fallbackId }

        // 2. 若是父分类，先删除子分类
        let all = try context.fetch(FetchDescriptor<DishCategoryModel>())
        let children = all.filter { $0.parentId == id }
        children.forEach { context.delete($0) }

        // 3. 删除自身
        let selfDescriptor = FetchDescriptor<DishCategoryModel>(
            predicate: #Predicate { $0.id == id }
        )
        if let model = try context.fetch(selfDescriptor).first {
            context.delete(model)
        }

        try context.save()
    }

    func updateOrdinals(_ ordinals: [(id: UUID, ordinal: Int)]) async throws {
        for item in ordinals {
            let itemId = item.id        // tuple 的属性也不能在 #Predicate 中直接访问
            let newOrdinal = item.ordinal
            let descriptor = FetchDescriptor<DishCategoryModel>(
                predicate: #Predicate { $0.id == itemId }
            )
            if let model = try context.fetch(descriptor).first {
                model.ordinal = newOrdinal
            }
        }
        try context.save()
    }
}
