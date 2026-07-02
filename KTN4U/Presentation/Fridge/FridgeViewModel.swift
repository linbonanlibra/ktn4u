import SwiftUI
import SwiftData

// MARK: - FridgeViewModel

@Observable
@MainActor
final class FridgeViewModel {
    var items: [FridgeItem] = []
    var isLoading = false
    var errorMessage: String?

    private var useCase: FridgeUseCase?

    func setup(context: ModelContext) {
        useCase = FridgeUseCase(repository: SDFridgeRepository(context: context))
    }

    func load() async {
        guard let useCase else { return }
        isLoading = true
        defer { isLoading = false }
        items = (try? await useCase.allItems()) ?? []
    }

    func delete(id: UUID) async {
        guard let useCase else { return }
        try? await useCase.deleteItem(id: id)
        await load()
    }

    func addItem(_ item: FridgeItem) async {
        guard let useCase else { return }
        try? await useCase.addItem(item)
        await load()
    }
}
