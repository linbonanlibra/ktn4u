import Testing
import Foundation
@testable import KTN4U

// MARK: - CategoryTreeTests

@Suite("DishCategory Tree")
struct CategoryTreeTests {

    @Test func topLevelIdentification() {
        let top = DishCategory(id: .init(), name: "肉类", parentId: nil, ordinal: 0)
        let child = DishCategory(id: .init(), name: "猪肉", parentId: top.id, ordinal: 0)
        #expect(top.isTopLevel == true)
        #expect(child.isTopLevel == false)
    }

    @Test func parentChildRelationship() {
        let parentId = UUID()
        let children = (0..<3).map { i in
            DishCategory(id: .init(), name: "子\(i)", parentId: parentId, ordinal: i)
        }
        let group = Dictionary(grouping: children, by: { $0.parentId! })
        #expect(group[parentId]?.count == 3)
    }
}
