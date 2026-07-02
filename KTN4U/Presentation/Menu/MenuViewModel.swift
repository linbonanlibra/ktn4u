import SwiftUI
import SwiftData

// MARK: - MenuViewModel
// Phase 3 注：MenuOrderView / RandomMenuView 已将各自的状态内联管理；
// 此 ViewModel 保留用于未来需要跨视图共享菜单状态的场景。

@Observable
@MainActor
final class MenuViewModel {
    var isLoading      = false
    var errorMessage: String?
    var preferences    = MenuPreferences()
    var generatedDishes: [Dish] = []

    // MARK: Save Helper (可被多个视图复用)

    /// 将一组菜品保存为今日菜单历史条目
    func saveMenu(
        dishes: [Dish],
        categoryMap: [UUID: String],
        context: ModelContext
    ) {
        let entries = dishes.map { dish in
            MenuEntry(
                id: UUID(),
                dishId: dish.id,
                dishName: dish.name,
                categoryName: categoryMap[dish.categoryId] ?? "未分类",
                coverPhotoFilename: dish.coverPhotoFilename
            )
        }
        let menu  = Menu(id: UUID(), date: .now, entries: entries)
        let model = MenuHistoryModel.from(menu)
        context.insert(model)
    }
}
