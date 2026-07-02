import Testing
import Foundation
@testable import KTN4U

// MARK: - MenuRecommendationTests

@Suite("LocalRuleMenuStrategy")
struct MenuRecommendationTests {

    let strategy = LocalRuleMenuStrategy()

    // 生成数量不超过 preferences.count
    @Test func respectsCount() async {
        let dishes = makeDishes(count: 10)
        let prefs = MenuPreferences(count: 3)
        let result = await strategy.recommend(
            preferences: prefs, from: dishes,
            categories: [], fridgeItems: [], recentMenus: []
        )
        #expect(result.count <= 3)
    }

    // 菜品不足时不崩溃，返回实际数量
    @Test func fewerDishesThanRequested() async {
        let dishes = makeDishes(count: 2)
        let prefs = MenuPreferences(count: 5)
        let result = await strategy.recommend(
            preferences: prefs, from: dishes,
            categories: [], fridgeItems: [], recentMenus: []
        )
        #expect(result.count <= 2)
    }

    // 空菜库返回空结果
    @Test func emptyDishPool() async {
        let result = await strategy.recommend(
            preferences: MenuPreferences(), from: [],
            categories: [], fridgeItems: [], recentMenus: []
        )
        #expect(result.isEmpty)
    }

    // 熟练度过滤：allowLowProficiency=false 时不选 Lv.0 菜（在有 Lv.1+ 菜的情况下）
    @Test func proficiencyFilter() async {
        let lowDish = Dish(id: .init(), name: "新菜", categoryId: .init(),
                           coverPhotoFilename: nil, photoFilenames: [], note: "", xp: 0, createdAt: .now)
        let highDish = Dish(id: .init(), name: "熟悉菜", categoryId: .init(),
                            coverPhotoFilename: nil, photoFilenames: [], note: "", xp: 10, createdAt: .now)
        var prefs = MenuPreferences(count: 1)
        prefs.allowLowProficiency = false

        let result = await strategy.recommend(
            preferences: prefs, from: [lowDish, highDish],
            categories: [], fridgeItems: [], recentMenus: []
        )
        // 应优先选到高熟练度菜品
        #expect(result.first?.id == highDish.id)
    }
}

// MARK: - Helpers

private func makeDishes(count: Int) -> [Dish] {
    (0..<count).map { i in
        Dish(id: .init(), name: "菜品\(i)", categoryId: .init(),
             coverPhotoFilename: nil, photoFilenames: [], note: "", xp: 10 + i, createdAt: .now)
    }
}
