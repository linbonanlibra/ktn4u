import SwiftUI
import SwiftData

// MARK: - DishListView
// @Query 动态过滤：新增菜品后网格自动刷新，无需手动 reload

struct DishListView: View {
    let categoryId: UUID
    let categoryName: String

    @Query private var dishModels: [DishModel]
    @State private var searchText = ""
    @State private var showAddDish = false

    // MARK: Init — 动态 filter

    init(categoryId: UUID, categoryName: String) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        // #Predicate 需要捕获纯 UUID（不能用 self.categoryId）
        let id = categoryId
        _dishModels = Query(
            filter: #Predicate<DishModel> { $0.categoryId == id },
            sort: \DishModel.name
        )
    }

    // MARK: Computed

    private var filtered: [DishModel] {
        guard !searchText.isEmpty else { return dishModels }
        return dishModels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: Body

    var body: some View {
        Group {
            if !searchText.isEmpty && filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if dishModels.isEmpty {
                EmptyStateView(
                    icon: "fork.knife",
                    title: "还没有菜品",
                    message: "点击右上角 + 添加第一道菜",
                    action: { showAddDish = true },
                    actionLabel: "添加菜品"
                )
            } else {
                dishGrid
            }
        }
        .navigationTitle(categoryName)
        .searchable(text: $searchText, prompt: "搜索菜品")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddDish = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddDish) {
            AddDishView(preselectedCategoryId: categoryId)
        }
    }

    // MARK: Grid

    private var dishGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160, maximum: 200))],
                spacing: 14
            ) {
                ForEach(filtered) { model in
                    NavigationLink(destination: DishDetailView(dishId: model.id)) {
                        DishCard(dish: model.toDomain())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        DishListView(categoryId: UUID(), categoryName: "猪肉")
    }
}
