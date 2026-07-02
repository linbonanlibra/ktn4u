import Foundation

// MARK: - Menu

/// 已生成并保存的菜单（历史快照）
struct Menu: Identifiable, Sendable {
    let id: UUID
    var date: Date
    /// 快照时的菜品信息（即使菜品被删除，历史菜单仍可正常展示）
    var entries: [MenuEntry]
}

// MARK: - MenuEntry

/// 菜单条目（菜品快照）
struct MenuEntry: Identifiable, Sendable {
    let id: UUID
    let dishId: UUID        // 原菜品 ID，可能已不存在
    var dishName: String    // 快照名称
    var categoryName: String
    var coverPhotoFilename: String?
}

// MARK: - MenuPreferences

/// 随机菜单生成参数
struct MenuPreferences: Sendable {
    var count: Int = 3
    var tastes: Set<Taste> = []
    var prioritizeFridge: Bool = true
    var allowLowProficiency: Bool = false  // false = 要求 Lv.1+

    enum Taste: String, CaseIterable, Identifiable, Sendable {
        case mild         = "清淡"
        case spicy        = "麻辣"
        case sourSweet    = "酸甜"
        case savory       = "咸鲜"
        case fragrantSpicy = "香辣"

        var id: String { rawValue }
    }
}
