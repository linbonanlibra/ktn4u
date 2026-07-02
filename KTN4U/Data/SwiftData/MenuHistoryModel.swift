import Foundation
import SwiftData

// MARK: - MenuHistoryModel

/// 菜单历史快照（即使原菜品被删除，历史仍可正常展示）
@Model
final class MenuHistoryModel {
    @Attribute(.unique) var id: UUID
    var date: Date

    // 快照数据（与原菜品解耦）
    var entryIds: [UUID]            // 条目 UUID
    var dishIds: [UUID]             // 原菜品 UUID（用于"复用"跳转）
    var dishNames: [String]         // 菜品名称快照
    var categoryNames: [String]     // 分类名称快照
    var coverPhotoFilenames: [String?]  // 封面图文件名快照

    init(
        id: UUID = UUID(),
        date: Date = .now,
        entryIds: [UUID] = [],
        dishIds: [UUID] = [],
        dishNames: [String] = [],
        categoryNames: [String] = [],
        coverPhotoFilenames: [String?] = []
    ) {
        self.id = id
        self.date = date
        self.entryIds = entryIds
        self.dishIds = dishIds
        self.dishNames = dishNames
        self.categoryNames = categoryNames
        self.coverPhotoFilenames = coverPhotoFilenames
    }
}

// MARK: - Mapping

extension MenuHistoryModel {
    func toDomain() -> Menu {
        let entries = zip(zip(entryIds, dishIds), zip(dishNames, zip(categoryNames, coverPhotoFilenames)))
            .map { args -> MenuEntry in
                let ((entryId, dishId), (dishName, (categoryName, cover))) = args
                return MenuEntry(
                    id: entryId,
                    dishId: dishId,
                    dishName: dishName,
                    categoryName: categoryName,
                    coverPhotoFilename: cover
                )
            }
        return Menu(id: id, date: date, entries: entries)
    }

    static func from(_ menu: Menu) -> MenuHistoryModel {
        MenuHistoryModel(
            id: menu.id,
            date: menu.date,
            entryIds: menu.entries.map(\.id),
            dishIds: menu.entries.map(\.dishId),
            dishNames: menu.entries.map(\.dishName),
            categoryNames: menu.entries.map(\.categoryName),
            coverPhotoFilenames: menu.entries.map(\.coverPhotoFilename)
        )
    }
}
