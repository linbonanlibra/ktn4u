import SwiftUI
import SwiftData

// MARK: - RandomMenuView
// 骰子推荐：参数面板 + 同页面展示推荐结果 + 保存

struct RandomMenuView: View {

    @Query(sort: \DishModel.name)             private var allDishModels: [DishModel]
    @Query(sort: \FridgeItemModel.expiryDate) private var fridgeModels: [FridgeItemModel]
    @Query(sort: \DishCategoryModel.ordinal)  private var categoryModels: [DishCategoryModel]
    @Query(sort: \MenuHistoryModel.date, order: .reverse) private var historyModels: [MenuHistoryModel]
    @Environment(\.modelContext) private var modelContext

    @State private var preferences = MenuPreferences()
    @State private var generatedDishes: [Dish] = []
    @State private var hasGenerated = false
    @State private var isGenerating = false
    @State private var isSaving = false
    @State private var showSaveSuccess = false

    private let strategy = LocalRuleMenuStrategy()

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                paramsCard
                generateButton

                if hasGenerated {
                    resultSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
            .animation(.spring(duration: 0.4), value: hasGenerated)
        }
        .navigationTitle("骰子推荐")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .top) {
            if showSaveSuccess { saveToast }
        }
    }

    // MARK: - Parameters Card

    private var paramsCard: some View {
        VStack(alignment: .leading, spacing: 20) {

            // 道数
            Stepper(value: $preferences.count, in: 1...8) {
                HStack {
                    Text("推荐道数")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(preferences.count) 道")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Divider()

            // 口味偏好
            VStack(alignment: .leading, spacing: 10) {
                Text("口味偏好（可多选）")
                    .font(.subheadline.bold())

                FlowLayout(spacing: 8) {
                    ForEach(MenuPreferences.Taste.allCases) { taste in
                        TasteChip(
                            label: taste.rawValue,
                            isSelected: preferences.tastes.contains(taste)
                        ) {
                            withAnimation(.spring(duration: 0.2)) {
                                if preferences.tastes.contains(taste) {
                                    preferences.tastes.remove(taste)
                                } else {
                                    preferences.tastes.insert(taste)
                                }
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }

            Divider()

            // 开关组
            Toggle(isOn: $preferences.prioritizeFridge) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("优先使用冰箱食材")
                            .font(.subheadline.bold())
                        Text("匹配冰箱存货，减少浪费")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "refrigerator.fill")
                        .foregroundStyle(.blue)
                }
            }

            Toggle(isOn: $preferences.allowLowProficiency) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("包含生疏菜品")
                            .font(.subheadline.bold())
                        Text("开启后也会推荐 Lv.0 的新菜")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView().tint(.white).controlSize(.small)
                } else {
                    Image(systemName: "dice.fill")
                }
                Text(isGenerating ? "生成中…" : (hasGenerated ? "换一批" : "生成今日菜单"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(isGenerating ? .gray : .orange)
        .disabled(isGenerating || allDishModels.isEmpty)
        .overlay {
            if allDishModels.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                    Text("菜品库为空，先去添加菜品吧")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("今日推荐")
                    .font(.headline)
                Spacer()
                // 保存按钮
                Button {
                    Task { await saveMenu() }
                } label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("保存菜单", systemImage: "square.and.arrow.down")
                            .font(.subheadline.bold())
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || generatedDishes.isEmpty)
            }

            if generatedDishes.isEmpty {
                ContentUnavailableView(
                    "菜品不足",
                    systemImage: "fork.knife",
                    description: Text("菜品库菜品较少，尝试开启「包含生疏菜品」")
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(generatedDishes) { dish in
                        NavigationLink(destination: DishDetailView(dishId: dish.id)) {
                            ResultDishRow(dish: dish)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Async Actions

    private func generate() async {
        isGenerating = true
        defer { isGenerating = false }

        let dishes     = allDishModels.map { $0.toDomain() }
        let fridge     = fridgeModels.map { $0.toDomain() }
        let categories = categoryModels.map { $0.toDomain() }
        let history    = historyModels.prefix(20).map { $0.toDomain() }

        let result = await strategy.recommend(
            preferences: preferences,
            from: dishes,
            categories: categories,
            fridgeItems: fridge,
            recentMenus: Array(history)
        )

        withAnimation(.spring(duration: 0.35)) {
            generatedDishes = result
            hasGenerated = true
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func saveMenu() async {
        guard !generatedDishes.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }

        let catMap = Dictionary(uniqueKeysWithValues: categoryModels.map { ($0.id, $0.name) })
        let entries = generatedDishes.map { dish in
            MenuEntry(
                id: UUID(),
                dishId: dish.id,
                dishName: dish.name,
                categoryName: catMap[dish.categoryId] ?? "未分类",
                coverPhotoFilename: dish.coverPhotoFilename
            )
        }

        let menu = Menu(id: UUID(), date: .now, entries: entries)
        modelContext.insert(MenuHistoryModel.from(menu))

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { showSaveSuccess = true }
        try? await Task.sleep(for: .seconds(1.8))
        withAnimation { showSaveSuccess = false }
    }

    // MARK: - Toast

    private var saveToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text("菜单已保存！")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 6, y: 3)
        .padding(.top, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - TasteChip

private struct TasteChip: View {
    let label: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.12),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ResultDishRow

private struct ResultDishRow: View {
    let dish: Dish

    var body: some View {
        HStack(spacing: 12) {
            // 封面缩略图
            Group {
                if let filename = dish.coverPhotoFilename,
                   let url = ImageFileStorage.url(for: filename) {
                    AsyncImage(url: url) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: { Rectangle().fill(.quaternary) }
                } else {
                    Rectangle().fill(.quaternary)
                        .overlay { Image(systemName: "fork.knife").foregroundStyle(.tertiary) }
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // 名称 + 熟练度
            VStack(alignment: .leading, spacing: 5) {
                Text(dish.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                ProficiencyBar(xp: dish.xp, showLabel: false)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - FlowLayout (自动换行的多选 chips)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        var rows: [[LayoutSubview]] = [[]]
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width + spacing > width && !rows.last!.isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentRowWidth += size.width + spacing
        }

        let totalHeight = rows.reduce(0.0) { acc, row in
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            return acc + rowHeight + spacing
        }
        return CGSize(width: width, height: max(0, totalHeight - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var rows: [[LayoutSubview]] = [[]]
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width + spacing > bounds.width && !rows.last!.isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentRowWidth += size.width + spacing
        }

        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
}

#Preview { NavigationStack { RandomMenuView() } }
