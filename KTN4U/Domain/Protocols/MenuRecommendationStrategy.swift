import Foundation

// MARK: - MenuRecommendationStrategy

/// 菜单推荐算法协议（预留 AI 接入口）
/// 初版由 LocalRuleMenuStrategy 实现；未来可无缝替换为 AI 版本
protocol MenuRecommendationStrategy: Sendable {
    func recommend(
        preferences: MenuPreferences,
        from dishes: [Dish],
        categories: [DishCategory],
        fridgeItems: [FridgeItem],
        recentMenus: [Menu]
    ) async -> [Dish]
}
