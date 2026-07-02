import Foundation

// MARK: - CookingRecord

/// 单次烹饪记录，是 XP 的唯一来源
struct CookingRecord: Identifiable, Sendable {
    let id: UUID
    let dishId: UUID
    var date: Date
    var photoFilenames: [String]   // 存沙盒文件名，由 ImageFileStorage 管理
    var note: String

    // MARK: XP 计算

    /// 本次记录产生的 XP（上限 10）
    var xpEarned: Int {
        var xp = 5  // 基础打卡 XP
        if !photoFilenames.isEmpty { xp += 3 }          // 有照片
        if !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { xp += 2 }  // 有文字
        return min(xp, 10)
    }
}
