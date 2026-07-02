import Foundation
import SwiftData

// MARK: - FridgeItemModel

@Model
final class FridgeItemModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var purchaseDate: Date
    var expiryDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        purchaseDate: Date = .now,
        expiryDate: Date
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
    }
}

// MARK: - Mapping

extension FridgeItemModel {
    func toDomain() -> FridgeItem {
        FridgeItem(
            id: id,
            name: name,
            quantity: quantity,
            unit: unit,
            purchaseDate: purchaseDate,
            expiryDate: expiryDate
        )
    }

    static func from(_ domain: FridgeItem) -> FridgeItemModel {
        FridgeItemModel(
            id: domain.id,
            name: domain.name,
            quantity: domain.quantity,
            unit: domain.unit,
            purchaseDate: domain.purchaseDate,
            expiryDate: domain.expiryDate
        )
    }

    func update(from domain: FridgeItem) {
        name = domain.name
        quantity = domain.quantity
        unit = domain.unit
        purchaseDate = domain.purchaseDate
        expiryDate = domain.expiryDate
    }
}
