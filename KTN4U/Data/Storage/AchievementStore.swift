import Foundation

// MARK: - AchievementStore
// 用 UserDefaults 持久化成就解锁记录（key → 解锁时间）
// 不使用 SwiftData 以保持轻量，成就数据量极小（固定 10 条）

struct AchievementStore {

    private static let defaults = UserDefaults.standard
    private static let key      = "com.ktn4u.achievements.v1"

    // MARK: Read

    /// 返回所有已解锁成就的 [id: unlockDate]
    static func loadAll() -> [String: Date] {
        guard
            let data = defaults.data(forKey: key),
            let dict = try? JSONDecoder().decode([String: Date].self, from: data)
        else { return [:] }
        return dict
    }

    static func unlockedIds() -> Set<String> { Set(loadAll().keys) }

    // MARK: Write

    /// 将新解锁的成就 ID 写入持久化（已解锁的 ID 保持原有日期不覆盖）
    static func markUnlocked(_ ids: [String], at date: Date = .now) {
        guard !ids.isEmpty else { return }
        var current = loadAll()
        for id in ids where current[id] == nil {
            current[id] = date
        }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }

    /// 清空所有成就（调试 / 重置用）
    static func reset() { defaults.removeObject(forKey: key) }
}
