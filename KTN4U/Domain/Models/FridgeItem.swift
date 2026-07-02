import Foundation

// MARK: - FridgeItem

/// 冰箱食材
struct FridgeItem: Identifiable, Sendable {
    let id: UUID
    var name: String
    var quantity: Double
    var unit: String        // 克 / 毫升 / 个 / 根 / 棵 / 袋 等
    var purchaseDate: Date
    var expiryDate: Date

    // MARK: Status

    enum Status: Sendable {
        case expired            // 已过期
        case warning            // ≤ 3 天
        case normal             // 正常
    }

    var status: Status {
        let days = daysUntilExpiry
        if days < 0 { return .expired }
        if days <= 3 { return .warning }
        return .normal
    }

    /// 距过期天数（负数表示已过期）
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: .now, to: expiryDate).day ?? 0
    }
}

// MARK: - Common Units

extension FridgeItem {
    static let commonUnits: [String] = ["克", "毫升", "个", "根", "棵", "袋", "块", "片", "斤"]
}
