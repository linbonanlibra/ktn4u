import Foundation
import SwiftData

// MARK: - DishModel

@Model
final class DishModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryId: UUID
    var coverPhotoFilename: String?
    var photoFilenames: [String]
    var note: String
    var xp: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var cookingRecords: [CookingRecordModel] = []

    init(
        id: UUID = UUID(),
        name: String,
        categoryId: UUID,
        coverPhotoFilename: String? = nil,
        photoFilenames: [String] = [],
        note: String = "",
        xp: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryId = categoryId
        self.coverPhotoFilename = coverPhotoFilename
        self.photoFilenames = photoFilenames
        self.note = note
        self.xp = xp
        self.createdAt = createdAt
    }
}

// MARK: - Mapping

extension DishModel {
    func toDomain() -> Dish {
        Dish(
            id: id,
            name: name,
            categoryId: categoryId,
            coverPhotoFilename: coverPhotoFilename,
            photoFilenames: photoFilenames,
            note: note,
            xp: xp,
            createdAt: createdAt
        )
    }

    static func from(_ domain: Dish) -> DishModel {
        DishModel(
            id: domain.id,
            name: domain.name,
            categoryId: domain.categoryId,
            coverPhotoFilename: domain.coverPhotoFilename,
            photoFilenames: domain.photoFilenames,
            note: domain.note,
            xp: domain.xp,
            createdAt: domain.createdAt
        )
    }

    func update(from domain: Dish) {
        name = domain.name
        categoryId = domain.categoryId
        coverPhotoFilename = domain.coverPhotoFilename
        photoFilenames = domain.photoFilenames
        note = domain.note
        xp = domain.xp
    }
}
