import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - ExportManager
// 将全部数据序列化为 JSON，写入临时文件后通过 ShareLink 分享

struct ExportManager {

    // MARK: - Data Structures

    struct KTN4UBackup: Codable {
        let version       = "1.0"
        let exportedAt: Date
        let dishes: [BackupDish]
        let menuHistory: [BackupMenu]
        let achievements: [String: Date]    // id → unlockDate
    }

    struct BackupDish: Codable {
        let id: UUID
        let name: String
        let categoryName: String
        let xp: Int
        let levelName: String
        let createdAt: Date
        let cookingRecords: [BackupRecord]
    }

    struct BackupRecord: Codable {
        let date: Date
        let note: String
        let xpEarned: Int
        let photoCount: Int
    }

    struct BackupMenu: Codable {
        let date: Date
        let dishes: [String]
    }

    // MARK: - Build Export

    @MainActor
    static func buildExportURL(context: ModelContext) throws -> URL {
        // ── 1. Fetch all data ──────────────────────────────────────
        let dishes    = (try? context.fetch(FetchDescriptor<DishModel>())) ?? []
        let records   = (try? context.fetch(FetchDescriptor<CookingRecordModel>())) ?? []
        let categories = (try? context.fetch(FetchDescriptor<DishCategoryModel>())) ?? []
        let menus     = (try? context.fetch(FetchDescriptor<MenuHistoryModel>())) ?? []

        let catMap   = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
        let recByDish: [UUID: [CookingRecordModel]] = Dictionary(
            grouping: records, by: \.dishId
        )

        // ── 2. Map to Codable structures ───────────────────────────
        let backupDishes: [BackupDish] = dishes.map { dish in
            let dishRecords = (recByDish[dish.id] ?? []).sorted { $0.date < $1.date }
            return BackupDish(
                id:           dish.id,
                name:         dish.name,
                categoryName: catMap[dish.categoryId] ?? "未分类",
                xp:           dish.xp,
                levelName:    ProficiencyLevel.current(xp: dish.xp).name,
                createdAt:    dish.createdAt,
                cookingRecords: dishRecords.map {
                    BackupRecord(
                        date:       $0.date,
                        note:       $0.note,
                        xpEarned:   $0.xpEarned,
                        photoCount: $0.photoFilenames.count
                    )
                }
            )
        }

        let backupMenus: [BackupMenu] = menus.map {
            BackupMenu(date: $0.date, dishes: $0.dishNames)
        }

        let backup = KTN4UBackup(
            exportedAt:   Date.now,
            dishes:       backupDishes,
            menuHistory:  backupMenus,
            achievements: AchievementStore.loadAll()
        )

        // ── 3. Encode → temp file ──────────────────────────────────
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(backup)

        let dateStr = ISO8601DateFormatter().string(from: Date.now)
            .replacingOccurrences(of: ":", with: "-")
        let filename = "KTN4U_backup_\(dateStr).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }
}

// MARK: - ExportFile (ShareLink compatible)

struct ExportFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { file in
            SentTransferredFile(file.url)
        }
    }
}
