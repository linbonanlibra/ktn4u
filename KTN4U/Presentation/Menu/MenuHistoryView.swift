import SwiftUI
import SwiftData

// MARK: - MenuHistoryView
// 历史菜单：@Query 驱动，按日期分组，滑动删除，「复用」保存今日新副本

struct MenuHistoryView: View {

    @Query(sort: \MenuHistoryModel.date, order: .reverse) private var menus: [MenuHistoryModel]
    @Environment(\.modelContext) private var modelContext

    @State private var reuseSuccess = false

    // 按「年-月-日」字符串分组，保持降序
    private var grouped: [(key: String, items: [MenuHistoryModel])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var dict: [String: [MenuHistoryModel]] = [:]
        for menu in menus {
            let key = formatter.string(from: menu.date)
            dict[key, default: []].append(menu)
        }
        return dict.sorted { $0.key > $1.key }.map { (key: $0.key, items: $0.value) }
    }

    var body: some View {
        Group {
            if menus.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "还没有菜单记录",
                    message: "去「骰子推荐」或「手动点餐」生成第一份菜单"
                )
            } else {
                historyList
            }
        }
        .navigationTitle("历史菜单")
        .overlay(alignment: .top) {
            if reuseSuccess { reuseToast }
        }
    }

    // MARK: - List

    private var historyList: some View {
        List {
            ForEach(grouped, id: \.key) { section in
                Section(header: sectionHeader(section.key)) {
                    ForEach(section.items) { menu in
                        MenuHistoryRow(menu: menu) {
                            reuseMenu(menu)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(menu)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Section Header

    private func sectionHeader(_ dateKey: String) -> some View {
        let parts = dateKey.split(separator: "-")
        let month = parts.count > 1 ? "\(parts[1])月" : ""
        let day   = parts.count > 2 ? "\(parts[2])日" : ""

        // 正确解析日期 key 来判断是否今天
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        let isToday = Calendar.current.isDateInToday(
            keyFormatter.date(from: dateKey) ?? Date.distantPast
        )

        return HStack(spacing: 6) {
            Text("\(month)\(day)")
                .font(.subheadline.bold())
            if isToday {
                Text("今天")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
            }
        }
    }

    // MARK: - Reuse

    private func reuseMenu(_ menu: MenuHistoryModel) {
        // 创建今日新菜单副本
        let copy = MenuHistoryModel(
            id: UUID(),
            date: .now,
            entryIds: menu.entryIds.map { _ in UUID() },
            dishIds: menu.dishIds,
            dishNames: menu.dishNames,
            categoryNames: menu.categoryNames,
            coverPhotoFilenames: menu.coverPhotoFilenames
        )
        modelContext.insert(copy)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation { reuseSuccess = true }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation { reuseSuccess = false }
        }
    }

    // MARK: - Toast

    private var reuseToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.clockwise.circle.fill").foregroundStyle(.blue)
            Text("已复用为今日菜单")
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

// MARK: - MenuHistoryRow

private struct MenuHistoryRow: View {
    let menu: MenuHistoryModel
    let onReuse: () -> Void

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: menu.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 菜品名称列表
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(menu.dishNames.joined(separator: " · "))
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    Text("\(menu.dishNames.count) 道菜 · \(timeLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 复用按钮
                Button(action: onReuse) {
                    Label("复用", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            // 封面图片横排（最多 4 张）
            if menu.coverPhotoFilenames.compactMap({ $0 }).count > 0 {
                HStack(spacing: 6) {
                    ForEach(
                        menu.coverPhotoFilenames.compactMap { $0 }.prefix(4),
                        id: \.self
                    ) { filename in
                        if let url = ImageFileStorage.url(for: filename) {
                            AsyncImage(url: url) { img in
                                img.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: { Rectangle().fill(.quaternary) }
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview { NavigationStack { MenuHistoryView() } }
