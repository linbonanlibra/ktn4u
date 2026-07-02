import Foundation
import SwiftData

// MARK: - CookingRecordModel

@Model
final class CookingRecordModel {
    @Attribute(.unique) var id: UUID
    var dishId: UUID
    var date: Date
    var photoFilenames: [String]
    var note: String
    var xpEarned: Int

    // 反向关联（SwiftData 自动推断）
    var dish: DishModel?

    init(
        id: UUID = UUID(),
        dishId: UUID,
        date: Date = .now,
        photoFilenames: [String] = [],
        note: String = "",
        xpEarned: Int
    ) {
        self.id = id
        self.dishId = dishId
        self.date = date
        self.photoFilenames = photoFilenames
        self.note = note
        self.xpEarned = xpEarned
    }
}

// MARK: - Mapping

extension CookingRecordModel {
    func toDomain() -> CookingRecord {
        CookingRecord(id: id, dishId: dishId, date: date, photoFilenames: photoFilenames, note: note)
    }
}
