import Foundation

// MARK: - ProficiencyLevel

/// 熟练度等级定义，包含 XP 阈值与展示信息
struct ProficiencyLevel: Equatable, Sendable {
    let level: Int          // 0–5
    let name: String
    let emoji: String
    let xpThreshold: Int    // 达到该等级所需的累计 XP

    // 全部等级（升序，level 0 在前）
    static let all: [ProficiencyLevel] = [
        .init(level: 0, name: "生手",  emoji: "🔪", xpThreshold:   0),
        .init(level: 1, name: "学徒",  emoji: "🍳", xpThreshold:  10),
        .init(level: 2, name: "熟悉",  emoji: "👨‍🍳", xpThreshold:  30),
        .init(level: 3, name: "熟练",  emoji: "⭐", xpThreshold:  70),
        .init(level: 4, name: "精通",  emoji: "🌟", xpThreshold: 150),
        .init(level: 5, name: "大师",  emoji: "👑", xpThreshold: 300),
    ]

    /// 根据累计 XP 返回当前等级
    static func current(xp: Int) -> ProficiencyLevel {
        all.reversed().first { $0.xpThreshold <= xp } ?? all[0]
    }

    /// 下一个等级；已是大师则返回 nil
    static func next(xp: Int) -> ProficiencyLevel? {
        let cur = current(xp: xp)
        guard cur.level < 5 else { return nil }
        return all[cur.level + 1]
    }

    /// 当前等级内的进度 (0.0–1.0)；大师返回 1.0
    static func progress(xp: Int) -> Double {
        let cur = current(xp: xp)
        guard let nxt = next(xp: xp) else { return 1.0 }
        let range = Double(nxt.xpThreshold - cur.xpThreshold)
        let earned = Double(xp - cur.xpThreshold)
        return min(earned / range, 1.0)
    }

    /// 距离下一级还需要多少 XP；已是大师返回 0
    static func xpToNextLevel(xp: Int) -> Int {
        guard let nxt = next(xp: xp) else { return 0 }
        return nxt.xpThreshold - xp
    }
}
