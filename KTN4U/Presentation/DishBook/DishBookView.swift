import SwiftUI
import SwiftData

// MARK: - DishBookView
// @Query 直驱 + 全局 .searchable 搜索

struct DishBookView: View {

    @Query(sort: \DishCategoryModel.ordinal) private var allCategories: [DishCategoryModel]
    @Query(sort: \DishModel.name)            private var allDishes: [DishModel]

    @State private var showAddDish = false
    @State private var searchText  = ""

    // MARK: Computed

    private var topCategories: [DishCategoryModel] {
        allCategories.filter { $0.parentId == nil }
    }

    private func children(of parentId: UUID) -> [DishCategoryModel] {
        allCategories.filter { $0.parentId == parentId }.sorted { $0.ordinal < $1.ordinal }
    }

    private func dishCount(for categoryId: UUID) -> Int {
        allDishes.filter { $0.categoryId == categoryId }.count
    }

    private func totalDishCount(for parent: DishCategoryModel) -> Int {
        let childIds = children(of: parent.id).map(\.id)
        return dishCount(for: parent.id) + childIds.reduce(0) { $0 + dishCount(for: $1) }
    }

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var searchResults: [DishModel] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return allDishes.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    // MARK: Body

    var body: some View {
        Group {
            if isSearchActive {
                searchResultsView
            } else if topCategories.isEmpty {
                EmptyStateView(
                    icon: "book.closed",
                    title: "还没有菜品",
                    message: "点击右上角 + 开始录入第一道菜",
                    action: { showAddDish = true },
                    actionLabel: "添加菜品"
                )
            } else {
                scrollContent
            }
        }
        .navigationTitle("菜品库")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索菜品")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddDish = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddDish) { AddDishView() }
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsView: some View {
        if searchResults.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            ScrollView {
                // 命中关键词高亮提示
                HStack {
                    Text("找到 \(searchResults.count) 道菜")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 160, maximum: 200))],
                    spacing: 14
                ) {
                    ForEach(searchResults) { model in
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

    // MARK: - Category Grid

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                ForEach(topCategories) { parent in
                    parentSection(parent)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private func parentSection(_ parent: DishCategoryModel) -> some View {
        let childCategories = children(of: parent.id)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(parent.name).font(.headline)
                Spacer()
                let total = totalDishCount(for: parent)
                if total > 0 {
                    Text("\(total) 道").font(.caption).foregroundStyle(.secondary)
                }
            }

            if childCategories.isEmpty {
                NavigationLink(destination: DishListView(categoryId: parent.id, categoryName: parent.name)) {
                    CategoryCard(name: parent.name, count: dishCount(for: parent.id))
                }
                .buttonStyle(.plain)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 220))], spacing: 10) {
                    ForEach(childCategories) { child in
                        NavigationLink(destination: DishListView(categoryId: child.id, categoryName: child.name)) {
                            CategoryCard(name: child.name, count: dishCount(for: child.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - CategoryCard

private struct CategoryCard: View {
    let name: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.subheadline.bold()).lineLimit(1)
                Text(count == 0 ? "暂无菜品" : "\(count) 道菜").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview { NavigationStack { DishBookView() } }
