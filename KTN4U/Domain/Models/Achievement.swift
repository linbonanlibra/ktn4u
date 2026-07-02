import Foundation

// MARK: - Achievement

/// 成就条目
struct Achievement: Identifiable, Sendable {
    let id: String          // 稳定标识符，如 "first_5_dishes"
    let title: String
    let description: String
    let emoji: String
    var unlockedAt: Date?   // nil = 未解锁

    var isUnlocked: Bool { unlockedAt != nil }
}

// MARK: - Predefined Achievements

extension Achievement {
    static let all: [Achievement] = [
        Achievement(id: "first_dish",        title: "初入厨房",   description: "录入第一道菜品",         emoji: "🍽️"),
        Achievement(id: "five_dishes",        title: "初学乍练",   description: "录入 5 道菜品",           emoji: "📖"),
        Achievement(id: "ten_dishes",         title: "小有积累",   description: "录入 10 道菜品",          emoji: "📚"),
        Achievement(id: "thirty_dishes",      title: "菜谱丰富",   description: "录入 30 道菜品",          emoji: "🗂️"),
        Achievement(id: "first_lv2",          title: "熟能生巧",   description: "第一道菜品达到熟悉（Lv.2）",emoji: "⭐"),
        Achievement(id: "first_lv5",          title: "炉火纯青",   description: "第一道菜品达到大师（Lv.5）",emoji: "👑"),
        Achievement(id: "first_cook",         title: "开锅啦",     description: "完成第一次烹饪打卡",       emoji: "🥄"),
        Achievement(id: "ten_cooks",          title: "勤于练习",   description: "累计烹饪打卡 10 次",       emoji: "🔥"),
        Achievement(id: "fridge_manager",     title: "冰箱管家",   description: "冰箱同时有 5 种以上食材",   emoji: "🧊"),
        Achievement(id: "first_menu",         title: "今日菜单",   description: "生成并保存第一份菜单",      emoji: "📋"),
    ]
}
