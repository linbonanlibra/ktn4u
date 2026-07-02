import Foundation
import WidgetKit

// MARK: - AppGroupStore
//
// 主 App 与 Widget 之间的数据桥接层
// 用 App Group 的 UserDefaults 传递「即将过期食材」列表
// 真机运行时需在开发者账号中启用 App Group：group.com.ktn4u.app
// 模拟器若无对应 Provisioning Profile，UserDefaults(suiteName:) 返回 nil，
// 代码会静默失败，Widget 展示占位数据。

struct AppGroupStore {

    // MARK: Constants

    static let groupID   = "group.com.ktn4u.app"
    static let widgetKey = "com.ktn4u.widget.urgentItems"

    // MARK: - WidgetItem (可 Codable 的轻量数据结构)

    struct WidgetItem: Codable {
        let name: String
        let daysLeft: Int  // 负数 = 已过期
    }

    // MARK: Write (由主 App 调用)

    /// 将当前所有食材写入 App Group，并通知 Widget 刷新时间线
    static func writeUrgentItems(_ fridgeItems: [FridgeItem]) {
        let items = fridgeItems
            .filter { $0.status != .normal }
            .sorted { $0.expiryDate < $1.expiryDate }
            .map { WidgetItem(name: $0.name, daysLeft: $0.daysUntilExpiry) }

        guard let defaults = UserDefaults(suiteName: groupID) else { return }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: widgetKey)
        }

        // 通知 WidgetKit 刷新时间线
        WidgetCenter.shared.reloadTimelines(ofKind: "FridgeExpiryWidget")
    }

    // MARK: Read (由 Widget 调用)

    /// 读取上次写入的紧急食材列表
    static func readUrgentItems() -> [WidgetItem] {
        guard
            let defaults = UserDefaults(suiteName: groupID),
            let data = defaults.data(forKey: widgetKey),
            let items = try? JSONDecoder().decode([WidgetItem].self, from: data)
        else { return [] }
        return items
    }
}
