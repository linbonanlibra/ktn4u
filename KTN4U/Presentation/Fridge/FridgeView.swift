import SwiftUI
import SwiftData

// MARK: - FridgeView
// @Query 直驱，按过期状态自动分组，增删后立即刷新，同步更新 Widget 数据

struct FridgeView: View {

    @Query(sort: \FridgeItemModel.expiryDate) private var allItems: [FridgeItemModel]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddItem  = false
    @State private var editingItem: FridgeItem? = nil  // 非 nil 时弹出编辑 Sheet

    // MARK: - Status Grouping

    private var expiredItems: [FridgeItemModel] {
        allItems.filter { $0.daysUntilExpiry < 0 }
    }
    private var warningItems: [FridgeItemModel] {
        allItems.filter { let d = $0.daysUntilExpiry; return d >= 0 && d <= 3 }
    }
    private var normalItems: [FridgeItemModel] {
        allItems.filter { $0.daysUntilExpiry > 3 }
    }

    private var urgentCount: Int { expiredItems.count + warningItems.count }

    // MARK: - Body

    var body: some View {
        Group {
            if allItems.isEmpty {
                EmptyStateView(
                    icon: "refrigerator",
                    title: "冰箱空空如也",
                    message: "点击右上角 + 记录食材，到期前会提醒你",
                    action: { showAddItem = true },
                    actionLabel: "添加食材"
                )
            } else {
                itemList
            }
        }
        .navigationTitle("我的冰箱")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddItem = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // 添加新食材
        .sheet(isPresented: $showAddItem) {
            AddFridgeItemView { item in
                insert(item)
            }
        }
        // 编辑已有食材
        .sheet(item: $editingItem) { item in
            AddFridgeItemView(existingItem: item) { updated in
                update(updated)
            }
        }
    }

    // MARK: - List

    private var itemList: some View {
        List {
            // ── 汇总栏 ────────────────────────────
            if urgentCount > 0 {
                summaryBanner
            }

            // ── 过期 ──────────────────────────────
            if !expiredItems.isEmpty {
                Section {
                    ForEach(expiredItems) { model in
                        rowView(model)
                    }
                } header: {
                    statusHeader(
                        label: "已过期",
                        count: expiredItems.count,
                        color: .red
                    )
                }
            }

            // ── 即将过期 ──────────────────────────
            if !warningItems.isEmpty {
                Section {
                    ForEach(warningItems) { model in
                        rowView(model)
                    }
                } header: {
                    statusHeader(
                        label: "即将过期（3天内）",
                        count: warningItems.count,
                        color: .orange
                    )
                }
            }

            // ── 正常 ──────────────────────────────
            if !normalItems.isEmpty {
                Section {
                    ForEach(normalItems) { model in
                        rowView(model)
                    }
                } header: {
                    statusHeader(
                        label: "冰箱存货",
                        count: normalItems.count,
                        color: .green
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        // 下拉刷新：重新计算到期状态（Date.now 变更场景），同步 Widget
        .refreshable {
            syncWidgetData()
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func rowView(_ model: FridgeItemModel) -> some View {
        FridgeItemRow(item: model.toDomain())
            // 左滑：编辑
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    editingItem = model.toDomain()
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
                .tint(.blue)
            }
            // 右滑：删除
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    delete(model)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
    }

    // MARK: - Summary Banner

    private var summaryBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("\(urgentCount) 种食材需要注意")
                .font(.subheadline)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.orange.opacity(0.08))
    }

    // MARK: - Section Header

    private func statusHeader(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Mutations

    private func insert(_ item: FridgeItem) {
        modelContext.insert(FridgeItemModel.from(item))
        syncWidgetData()
    }

    private func update(_ item: FridgeItem) {
        let id = item.id
        let descriptor = FetchDescriptor<FridgeItemModel>(
            predicate: #Predicate { $0.id == id }
        )
        if let model = try? modelContext.fetch(descriptor).first {
            model.update(from: item)
        }
        syncWidgetData()
    }

    private func delete(_ model: FridgeItemModel) {
        let deletedId = model.id
        modelContext.delete(model)
        // 删除时 allItems 还未刷新，需手动排除已删条目
        let remaining = allItems.filter { $0.id != deletedId }.map { $0.toDomain() }
        AppGroupStore.writeUrgentItems(remaining)
    }

    /// 写入 App Group，触发 Widget 时间线刷新（增/改场景下 allItems 已是最新）
    private func syncWidgetData() {
        AppGroupStore.writeUrgentItems(allItems.map { $0.toDomain() })
    }
}

// MARK: - FridgeItemModel Helper

private extension FridgeItemModel {
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: .now, to: expiryDate).day ?? 0
    }
}

#Preview { NavigationStack { FridgeView() } }
