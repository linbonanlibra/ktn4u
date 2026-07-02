import Foundation
import SwiftData

// MARK: - DefaultCategorySeeder

/// 首次启动时写入预置分类树，之后由用户自行管理
@MainActor
struct DefaultCategorySeeder {

    static func seedIfNeeded(context: ModelContext) {
        // 已有数据则跳过
        let descriptor = FetchDescriptor<DishCategoryModel>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        // 预置二级分类树
        let tree: [(name: String, children: [String])] = [
            ("🥩 肉类",       ["猪肉", "牛羊肉", "鸡鸭鹅", "海鲜水产"]),
            ("🥦 蔬菜",       ["叶菜", "根茎类", "瓜茄类", "菌菇豆腐"]),
            ("🍜 主食",       ["面条 / 饺子", "米饭 / 粥", "包子 / 饼"]),
            ("🍲 汤品",       ["清汤", "浓汤 / 煲汤"]),
            ("🥚 蛋 & 豆制品", []),
            ("🍮 甜点 / 小吃", []),
        ]

        for (parentOrdinal, entry) in tree.enumerated() {
            let parentId = UUID()
            let parent = DishCategoryModel(
                id: parentId,
                name: entry.name,
                parentId: nil,
                ordinal: parentOrdinal
            )
            context.insert(parent)

            for (childOrdinal, childName) in entry.children.enumerated() {
                let child = DishCategoryModel(
                    id: UUID(),
                    name: childName,
                    parentId: parentId,
                    ordinal: childOrdinal
                )
                context.insert(child)
            }
        }

        try? context.save()
    }
}
