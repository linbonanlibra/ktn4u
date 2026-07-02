import SwiftUI
import SwiftData

// MARK: - KTN4UApp

@main
struct KTN4UApp: App {

    let container: ModelContainer

    init() {
        let schema = Schema([
            DishModel.self,
            DishCategoryModel.self,
            CookingRecordModel.self,
            FridgeItemModel.self,
            MenuHistoryModel.self,
        ])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("SwiftData ModelContainer 初始化失败：\(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task { seedDefaultData() }
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.didBecomeActiveNotification)
                ) { _ in
                    // 每次 App 激活时刷新 Widget 数据（日期可能已变）
                    refreshWidgetData()
                }
        }
        .modelContainer(container)
    }

    // MARK: - Private

    @MainActor
    private func seedDefaultData() {
        DefaultCategorySeeder.seedIfNeeded(context: container.mainContext)
    }

    @MainActor
    private func refreshWidgetData() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<FridgeItemModel>()
        let models = (try? context.fetch(descriptor)) ?? []
        AppGroupStore.writeUrgentItems(models.map { $0.toDomain() })
    }
}
