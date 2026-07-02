import Foundation
import SwiftData

// MARK: - DishCategoryModel

@Model
final class DishCategoryModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var parentId: UUID?     // nil = 顶级分类；通过 UUID 引用而非 SwiftData relationship，简化树操作
    var ordinal: Int

    init(id: UUID = UUID(), name: String, parentId: UUID? = nil, ordinal: Int = 0) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.ordinal = ordinal
    }
}

// MARK: - Mapping

extension DishCategoryModel {
    func toDomain() -> DishCategory {
        DishCategory(id: id, name: name, parentId: parentId, ordinal: ordinal)
    }

    static func from(_ domain: DishCategory) -> DishCategoryModel {
        DishCategoryModel(id: domain.id, name: domain.name, parentId: domain.parentId, ordinal: domain.ordinal)
    }

    func update(from domain: DishCategory) {
        name = domain.name
        parentId = domain.parentId
        ordinal = domain.ordinal
    }
}
