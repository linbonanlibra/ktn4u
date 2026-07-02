import SwiftUI
import SwiftData

// MARK: - DataManagementView
// 数据管理：备份导出 + 双重确认清空全部数据

struct DataManagementView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var showConfirm1  = false   // 第一次确认
    @State private var showConfirm2  = false   // 第二次确认
    @State private var isExporting   = false
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var resetDone     = false

    var body: some View {
        List {
            // ── 备份 ───────────────────────────────────────────────
            Section("数据备份") {
                exportRow
            }

            // ── 危险操作 ───────────────────────────────────────────
            Section {
                Button(role: .destructive) {
                    showConfirm1 = true
                } label: {
                    Label("清空全部数据", systemImage: "trash.fill")
                }
            } header: {
                Text("危险操作")
            } footer: {
                Text("清空后将重置为初始状态，包括默认分类，所有菜品/烹饪记录/冰箱数据/菜单历史将被永久删除。")
                    .font(.caption)
            }
        }
        .navigationTitle("数据管理")
        .navigationBarTitleDisplayMode(.inline)

        // ── 清空 · 第一次确认 ──────────────────────────────────────
        .alert("清空全部数据？", isPresented: $showConfirm1) {
            Button("取消", role: .cancel) {}
            Button("我了解风险，继续", role: .destructive) {
                showConfirm2 = true
            }
        } message: {
            Text("此操作将永久删除所有菜品、烹饪记录、冰箱食材和菜单历史，且无法恢复。")
        }

        // ── 清空 · 第二次确认 ──────────────────────────────────────
        .alert("最后确认：清空所有数据", isPresented: $showConfirm2) {
            Button("取消", role: .cancel) {}
            Button("清空全部数据", role: .destructive) { performReset() }
        } message: {
            Text("确认后数据将立即删除，无法恢复。")
        }

        // ── 清空成功提示 ───────────────────────────────────────────
        .alert("数据已清空", isPresented: $resetDone) {
            Button("好") {}
        } message: {
            Text("所有数据已删除，默认分类已重新初始化。")
        }
    }

    // MARK: - Export Row

    @ViewBuilder
    private var exportRow: some View {
        if isExporting {
            HStack {
                Label("正在生成备份…", systemImage: "square.and.arrow.up")
                Spacer()
                ProgressView().controlSize(.small)
            }
        } else if let url = exportURL {
            ShareLink(item: url) {
                Label("分享备份文件", systemImage: "square.and.arrow.up")
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                Task { await prepareExport() }
            } label: {
                Label("导出 JSON 备份", systemImage: "square.and.arrow.up")
            }
            if let err = exportError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Actions

    private func prepareExport() async {
        isExporting = true
        exportError = nil
        defer { isExporting = false }
        do {
            exportURL = try ExportManager.buildExportURL(context: modelContext)
        } catch {
            exportError = "导出失败：\(error.localizedDescription)"
        }
    }

    @MainActor
    private func performReset() {
        // ① SwiftData 批量删除（按依赖顺序：先子后父）
        try? modelContext.delete(model: CookingRecordModel.self)
        try? modelContext.delete(model: DishModel.self)
        try? modelContext.delete(model: DishCategoryModel.self)
        try? modelContext.delete(model: FridgeItemModel.self)
        try? modelContext.delete(model: MenuHistoryModel.self)
        try? modelContext.save()

        // ② 清空成就记录
        AchievementStore.reset()

        // ③ 清空 Widget 数据
        AppGroupStore.writeUrgentItems([])

        // ④ 重新写入默认分类
        DefaultCategorySeeder.seedIfNeeded(context: modelContext)

        resetDone = true
        exportURL = nil
    }
}

#Preview {
    NavigationStack { DataManagementView() }
}
