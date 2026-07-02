import Foundation

// MARK: - DishCategory

/// 菜品分类（支持二级树：parentId == nil 为一级分类）
struct DishCategory: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var parentId: UUID?     // nil 表示顶级分类
    var ordinal: Int        // 同级排序序号

    var isTopLevel: Bool { parentId == nil }
}
