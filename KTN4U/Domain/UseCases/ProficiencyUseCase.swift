import Foundation

// MARK: - ProficiencyUseCase

/// 熟练度 & XP 核心逻辑（纯计算，无副作用，可单元测试）
struct ProficiencyUseCase: Sendable {

    // MARK: XP Award

    /// 计算添加一条烹饪记录后的新 XP
    /// - Parameters:
    ///   - currentXP: 当前菜品的 XP
    ///   - record: 本次烹饪记录
    ///   - isFirstEver: 是否为该菜品的首次烹饪记录（享有首次解锁 +5 XP）
    /// - Returns: 新的累计 XP
    func newXP(currentXP: Int, for record: CookingRecord, isFirstEver: Bool) -> Int {
        var gained = record.xpEarned
        if isFirstEver { gained += 5 }  // 首次解锁奖励
        return currentXP + gained
    }

    // MARK: Level Up Detection

    /// 从 oldXP 增加到 newXP 时是否发生了等级提升
    func didLevelUp(from oldXP: Int, to newXP: Int) -> Bool {
        ProficiencyLevel.current(xp: oldXP).level < ProficiencyLevel.current(xp: newXP).level
    }

    /// 升级后达到的新等级
    func levelAfterLevelUp(newXP: Int) -> ProficiencyLevel {
        ProficiencyLevel.current(xp: newXP)
    }

    // MARK: Display Helpers

    func currentLevel(xp: Int) -> ProficiencyLevel {
        ProficiencyLevel.current(xp: xp)
    }

    func progress(xp: Int) -> Double {
        ProficiencyLevel.progress(xp: xp)
    }

    func xpToNextLevel(xp: Int) -> Int {
        ProficiencyLevel.xpToNextLevel(xp: xp)
    }
}
