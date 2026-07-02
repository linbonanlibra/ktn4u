import SwiftUI
import SwiftData

// MARK: - DishBookViewModel

@Observable
@MainActor
final class DishBookViewModel {
    var topCategories: [DishCategory] = []
    var childrenByParent: [UUID: [DishCategory]] = [:]
    var isLoading = false
    var errorMessage: String?

    private var categoryRepo: (any CategoryRepository)?

    func setup(context: ModelContext) {
        categoryRepo = SDCategoryRepository(context: context)
    }

    func loadCategories() async {
        guard let repo = categoryRepo else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await repo.fetchAll()
            topCategories = all.filter { $0.isTopLevel }.sorted { $0.ordinal < $1.ordinal }
            childrenByParent = Dictionary(grouping: all.filter { !$0.isTopLevel }, by: { $0.parentId! })
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
