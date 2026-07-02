import SwiftUI
import SwiftData

// MARK: - MenuOrderView
// 手动点餐：顶部分类 Tabs + 菜品网格 + 底部可展开的选菜托盘

struct MenuOrderView: View {

    @Query(sort: \DishCategoryModel.ordinal) private var allCategories: [DishCategoryModel]
    @Query(sort: \DishModel.name)             private var allDishes: [DishModel]
    @Environment(\.modelContext)             private var modelContext
    @Environment(\.dismiss)                  private var dismiss

    @State private var selectedCategoryId: UUID? = nil   // nil = 全部
    @State private var selectedDishIds: Set<UUID> = []
    @State private var trayExpanded = false
    @State private var isSaving = false
    @State private var showSaveSuccess = false

    // MARK: Computed

    /// 仅展示叶子分类（无子分类的那一级）
    private var leafCategories: [DishCategoryModel] {
        let parentIds = Set(allCategories.compactMap(\.parentId))
        return allCategories.filter { !parentIds.contains($0.id) }
    }

    private var displayedDishes: [DishModel] {
        guard let id = selectedCategoryId else { return allDishes }
        return allDishes.filter { $0.categoryId == id }
    }

    private var selectedDishModels: [DishModel] {
        allDishes.filter { selectedDishIds.contains($0.id) }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            categoryTabBar
            Divider()
            dishGrid
        }
        .navigationTitle("手动点餐")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !selectedDishIds.isEmpty { selectionTray }
        }
        .overlay {
            if showSaveSuccess { saveToast }
        }
    }

    // MARK: - Category Tabs

    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 全部
                CategoryTab(title: "全部", isSelected: selectedCategoryId == nil) {
                    withAnimation(.spring(duration: 0.25)) { selectedCategoryId = nil }
                }

                ForEach(leafCategories) { cat in
                    CategoryTab(title: cat.name, isSelected: selectedCategoryId == cat.id) {
                        withAnimation(.spring(duration: 0.25)) { selectedCategoryId = cat.id }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }

    // MARK: - Dish Grid

    private var dishGrid: some View {
        Group {
            if displayedDishes.isEmpty {
                EmptyStateView(
                    icon: "fork.knife",
                    title: "暂无菜品",
                    message: "去菜品库添加一些菜吧"
                )
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 160, maximum: 200))],
                        spacing: 14
                    ) {
                        ForEach(displayedDishes) { model in
                            let dish = model.toDomain()
                            SelectableDishCard(
                                dish: dish,
                                isSelected: selectedDishIds.contains(dish.id)
                            ) {
                                toggleSelection(dish.id)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 80)   // 为托盘留出空间
                }
            }
        }
    }

    private func toggleSelection(_ id: UUID) {
        withAnimation(.spring(duration: 0.28, bounce: 0.3)) {
            if selectedDishIds.contains(id) {
                selectedDishIds.remove(id)
            } else {
                selectedDishIds.insert(id)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Selection Tray

    private var selectionTray: some View {
        VStack(spacing: 0) {
            Divider()

            // 已选菜品滚动条（展开时显示）
            if trayExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedDishModels) { model in
                            DishChip(name: model.name) {
                                withAnimation { _ = selectedDishIds.remove(model.id) }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // 主操作行
            HStack(spacing: 12) {
                // 展开/收起 + 数量徽章
                Button {
                    withAnimation(.spring(duration: 0.3)) { trayExpanded.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: trayExpanded ? "chevron.down.circle" : "chevron.up.circle")
                        Text("\(selectedDishIds.count) 道")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                // 清空
                Button("清空") {
                    withAnimation { selectedDishIds.removeAll(); trayExpanded = false }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)

                // 保存菜单
                Button {
                    Task { await saveMenu() }
                } label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("保存今日菜单")
                            .font(.subheadline.bold())
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
    }

    // MARK: - Save

    private func saveMenu() async {
        guard !selectedDishIds.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }

        let catMap = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0.name) })
        let dishes = allDishes.filter { selectedDishIds.contains($0.id) }

        let entries = dishes.map { model in
            MenuEntry(
                id: UUID(),
                dishId: model.id,
                dishName: model.name,
                categoryName: catMap[model.categoryId] ?? "未分类",
                coverPhotoFilename: model.coverPhotoFilename
            )
        }

        let menu = Menu(id: UUID(), date: .now, entries: entries)
        modelContext.insert(MenuHistoryModel.from(menu))

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        selectedDishIds.removeAll()
        trayExpanded = false

        withAnimation { showSaveSuccess = true }
        try? await Task.sleep(for: .seconds(1.8))
        withAnimation { showSaveSuccess = false }
    }

    // MARK: - Save Toast

    private var saveToast: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("菜单已保存！")
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .shadow(radius: 6, y: 3)
            Spacer()
        }
        .padding(.top, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Category Tab Button

private struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold(isSelected))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.12),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SelectableDishCard

struct SelectableDishCard: View {
    let dish: Dish
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        DishCard(dish: dish)
            .overlay(alignment: .topLeading) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, Color.accentColor)
                        .padding(8)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                }
            }
            .scaleEffect(isSelected ? 0.96 : 1.0)
            .animation(.spring(duration: 0.25, bounce: 0.35), value: isSelected)
            .onTapGesture { onToggle() }
    }
}

// MARK: - DishChip

private struct DishChip: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Text(name)
                .font(.caption.bold())
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary, in: Capsule())
    }
}

// MARK: - Font bold extension helper

private extension Font {
    func bold(_ condition: Bool) -> Font {
        condition ? self.bold() : self
    }
}

#Preview { NavigationStack { MenuOrderView() } }
