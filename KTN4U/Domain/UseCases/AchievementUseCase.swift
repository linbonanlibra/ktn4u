import Foundation

// MARK: - AchievementUseCase

struct AchievementUseCase: Sendable {

    /// 根据当前数据快照计算哪些成就已解锁（返回需要新解锁的成就列表）
    /// - Parameters:
    ///   - alreadyUnlocked: 已解锁的成就 ID 集合
    ///   - totalDishes: 菜品总数
    ///   - totalCooks: 累计烹饪次数
    ///   - maxDishLevel: 当前拥有的最高菜品等级
    ///   - fridgeCount: 冰箱食材数量
    ///   - savedMenuCount: 已保存菜单数
    /// - Returns: 本次新解锁的成就
    func checkNewUnlocks(
        alreadyUnlocked: Set<String>,
        totalDishes: Int,
        totalCooks: Int,
        maxDishLevel: Int,
        fridgeCount: Int,
        savedMenuCount: Int
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        let conditions: [(id: String, met: Bool)] = [
            ("first_dish",      totalDishes >= 1),
            ("five_dishes",     totalDishes >= 5),
            ("ten_dishes",      totalDishes >= 10),
            ("thirty_dishes",   totalDishes >= 30),
            ("first_lv2",       maxDishLevel >= 2),
            ("first_lv5",       maxDishLevel >= 5),
            ("first_cook",      totalCooks >= 1),
            ("ten_cooks",       totalCooks >= 10),
            ("fridge_manager",  fridgeCount >= 5),
            ("first_menu",      savedMenuCount >= 1),
        ]

        for condition in conditions {
            guard condition.met, !alreadyUnlocked.contains(condition.id) else { continue }
            if let achievement = Achievement.all.first(where: { $0.id == condition.id }) {
                newlyUnlocked.append(achievement)
            }
        }

        return newlyUnlocked
    }
}
