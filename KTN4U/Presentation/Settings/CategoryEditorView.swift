import SwiftUI
import SwiftData

// MARK: - CategoryEditorView
// 两级分类树编辑器，同一个 View 复用：
//   parentId == nil  → 展示顶级分类
//   parentId != nil  → 展示该父分类的子分类
//
// 功能：拖动排序、左滑重命名、右滑删除（含 Alert 警告）、工具栏 + 新增

struct CategoryEditorView: View {

    var parentId: UUID? = nil      // nil = 顶级
    var title: String = "分类管理"

    // 全量加载后在 Swift 侧过滤，避免 #Predicate Optional 问题
    @Query(sort: \DishCategoryModel.ordinal) private var allCategories: [DishCategoryModel]
    @Query                                   private var allDishes: [DishModel]
    @Environment(\.modelContext) private var modelContext

    // ── 弹窗 / Alert 状态 ──────────────────────────────────────────
    @State private var showAddAlert    = false
    @State private var newName         = ""
    @State private var renameTarget: DishCategoryModel?
    @State private var renameText      = ""
    @State private var deleteTarget: DishCategoryModel?

    // MARK: - Computed helpers

    /// 当前层级的直接子分类
    private var items: [DishCategoryModel] {
        allCategories
            .filter { $0.parentId == parentId }
            .sorted { $0.ordinal < $1.ordinal }
    }

    private func children(of cat: DishCategoryModel) -> [DishCategoryModel] {
        allCategories.filter { $0.parentId == cat.id }
    }

    private func dishCount(in cat: DishCategoryModel) -> Int {
        allDishes.filter { $0.categoryId == cat.id }.count
    }

    /// 某一级分类下的总菜品数（含所有子分类）
    private func totalDishCount(of cat: DishCategoryModel) -> Int {
        let direct = dishCount(in: cat)
        let childDishes = children(of: cat).reduce(0) { $0 + dishCount(in: $1) }
        return direct + childDishes
    }

    // MARK: - Delete Warning

    private func deleteWarning(for cat: DishCategoryModel) -> String {
        let childCats  = children(of: cat)
        let totalDish  = totalDishCount(of: cat)

        if !childCats.isEmpty {
            return "删除「\(cat.name)」将同时删除 \(childCats.count) 个子分类和 \(totalDish) 道菜品，此操作不可撤销。"
        } else if totalDish > 0 {
            return "「\(cat.name)」下有 \(totalDish) 道菜品，删除后也将被删除，此操作不可撤销。"
        }
        return "确认删除「\(cat.name)」？"
    }

    // MARK: - Body

    var body: some View {
        List {
            ForEach(items) { cat in
                row(for: cat)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            renameTarget = cat
                            renameText   = cat.name
                        } label: {
                            Label("重命名", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteTarget = cat
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
            .onMove(perform: handleMove)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddAlert = true } label: { Image(systemName: "plus") }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }

        // ── 添加 Alert ─────────────────────────────────────────────
        .alert("添加分类", isPresented: $showAddAlert) {
            TextField("分类名称", text: $newName)
                .autocorrectionDisabled()
            Button("取消", role: .cancel) { newName = "" }
            Button("添加") { performAdd() }
        }

        // ── 重命名 Alert ───────────────────────────────────────────
        .alert("重命名", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("新名称", text: $renameText)
                .autocorrectionDisabled()
            Button("取消", role: .cancel) { renameTarget = nil }
            Button("保存") { performRename() }
        } message: {
            Text("修改「\(renameTarget?.name ?? "")」的名称")
        }

        // ── 删除确认 ───────────────────────────────────────────────
        .confirmationDialog(
            deleteTarget.map { deleteWarning(for: $0) } ?? "",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) { performDelete() }
            Button("取消", role: .cancel)       { deleteTarget = nil }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for cat: DishCategoryModel) -> some View {
        if parentId == nil {
            // 顶级分类：可导航进入子分类编辑
            NavigationLink(destination: CategoryEditorView(parentId: cat.id, title: cat.name)) {
                CategoryRowContent(
                    name: cat.name,
                    detail: sublabel(for: cat)
                )
            }
        } else {
            // 叶子分类：直接显示行（无下一级）
            CategoryRowContent(
                name: cat.name,
                detail: sublabel(for: cat)
            )
        }
    }

    private func sublabel(for cat: DishCategoryModel) -> String {
        if parentId == nil {
            let childCount = children(of: cat).count
            let dCount = totalDishCount(of: cat)
            if childCount > 0 {
                return "\(childCount) 个子分类 · \(dCount) 道菜"
            }
        }
        let d = dishCount(in: cat)
        return d == 0 ? "暂无菜品" : "\(d) 道菜"
    }

    // MARK: - Actions

    private func performAdd() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { newName = ""; return }
        let maxOrdinal = items.map(\.ordinal).max() ?? -1
        let cat = DishCategoryModel(
            name: trimmed,
            parentId: parentId,
            ordinal: maxOrdinal + 1
        )
        modelContext.insert(cat)
        newName = ""
    }

    private func performRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let target = renameTarget else { return }
        target.name = trimmed
        renameTarget = nil
    }

    private func performDelete() {
        guard let target = deleteTarget else { return }

        // 递归删除子分类和菜品
        for child in children(of: target) {
            allDishes
                .filter { $0.categoryId == child.id }
                .forEach { modelContext.delete($0) }
            modelContext.delete(child)
        }
        allDishes
            .filter { $0.categoryId == target.id }
            .forEach { modelContext.delete($0) }
        modelContext.delete(target)
        deleteTarget = nil
    }

    private func handleMove(from source: IndexSet, to destination: Int) {
        // 对当前层级的有序列表应用移动，然后更新 ordinal
        var reordered = items
        reordered.move(fromOffsets: source, toOffset: destination)
        for (i, cat) in reordered.enumerated() {
            cat.ordinal = i
        }
    }
}

// MARK: - CategoryRowContent

private struct CategoryRowContent: View {
    let name: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.body)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack { CategoryEditorView() }
}
