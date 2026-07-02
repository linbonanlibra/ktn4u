import SwiftUI
import SwiftData

// MARK: - ProfileViewModel

@Observable
@MainActor
final class ProfileViewModel {

    // MARK: Stats
    var totalDishes   = 0
    var totalCooks    = 0
    var menuCount     = 0
    var fridgeCount   = 0
    var highestLevel  = 0
    var levelCounts: [Int: Int] = [:]               // level → dish count

    // MARK: Recent Timeline
    var recentRecords: [(record: CookingRecord, dishName: String)] = []

    // MARK: Achievements
    var unlockedAchievements: [String: Date] = [:]  // id → unlockDate
    var newlyUnlocked: [Achievement] = []           // 本次 load 发现的新解锁

    // MARK: Export
    var exportURL: URL?
    var isExporting = false
    var exportError: String?

    var unlockedCount: Int { unlockedAchievements.count }
    var totalAchievements: Int { Achievement.all.count }

    // MARK: - Load

    func load(context: ModelContext) async {
        // ── 1. Dishes ──────────────────────────────────────────────
        let dishes = (try? context.fetch(FetchDescriptor<DishModel>())) ?? []
        totalDishes  = dishes.count
        highestLevel = dishes.map { ProficiencyLevel.current(xp: $0.xp).level }.max() ?? 0
        levelCounts  = Dictionary(
            grouping: dishes,
            by: { ProficiencyLevel.current(xp: $0.xp).level }
        ).mapValues(\.count)

        // ── 2. Cooking Records ─────────────────────────────────────
        let recDesc = FetchDescriptor<CookingRecordModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allRecords = (try? context.fetch(recDesc)) ?? []
        totalCooks = allRecords.count

        let nameMap = Dictionary(uniqueKeysWithValues: dishes.map { ($0.id, $0.name) })
        recentRecords = allRecords.prefix(10).map {
            (record: $0.toDomain(), dishName: nameMap[$0.dishId] ?? "未知菜品")
        }

        // ── 3. Fridge & Menus ──────────────────────────────────────
        fridgeCount = (try? context.fetchCount(FetchDescriptor<FridgeItemModel>())) ?? 0
        menuCount   = (try? context.fetchCount(FetchDescriptor<MenuHistoryModel>())) ?? 0

        // ── 4. Achievement Check ───────────────────────────────────
        let useCase = AchievementUseCase()
        let alreadyUnlocked = AchievementStore.unlockedIds()
        let newOnes = useCase.checkNewUnlocks(
            alreadyUnlocked: alreadyUnlocked,
            totalDishes:    totalDishes,
            totalCooks:     totalCooks,
            maxDishLevel:   highestLevel,
            fridgeCount:    fridgeCount,
            savedMenuCount: menuCount
        )
        if !newOnes.isEmpty {
            AchievementStore.markUnlocked(newOnes.map(\.id))
            newlyUnlocked = newOnes
        } else {
            newlyUnlocked = []
        }
        unlockedAchievements = AchievementStore.loadAll()
    }

    // MARK: - Export

    func prepareExport(context: ModelContext) async {
        isExporting = true
        exportError = nil
        defer { isExporting = false }
        do {
            exportURL = try ExportManager.buildExportURL(context: context)
        } catch {
            exportError = "导出失败：\(error.localizedDescription)"
        }
    }
}
