import Foundation

// MARK: - MenuRecommendationUseCase

struct MenuRecommendationUseCase: Sendable {
    let dishRepository: any DishRepository
    let fridgeRepository: any FridgeRepository
    let categoryRepository: any CategoryRepository
    let strategy: any MenuRecommendationStrategy

    /// 生成推荐菜单
    func recommend(preferences: MenuPreferences, recentMenus: [Menu]) async throws -> [Dish] {
        async let dishes = dishRepository.fetchAll()
        async let fridge = fridgeRepository.fetchAll()
        async let categories = categoryRepository.fetchAll()
        return await strategy.recommend(
            preferences: preferences,
            from: try dishes,
            categories: try categories,
            fridgeItems: try fridge,
            recentMenus: recentMenus
        )
    }
}
