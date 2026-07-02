import Foundation

// MARK: - Dish

/// 菜品（Domain 值对象）
struct Dish: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var categoryId: UUID
    var coverPhotoFilename: String?    // 封面图，对应沙盒文件名
    var photoFilenames: [String]       // 多图
    var note: String
    var xp: Int                        // 累计 XP，不直接修改，由 ProficiencyUseCase 管理
    var createdAt: Date

    // MARK: Derived

    var proficiencyLevel: ProficiencyLevel {
        ProficiencyLevel.current(xp: xp)
    }

    var proficiencyProgress: Double {
        ProficiencyLevel.progress(xp: xp)
    }
}
