import SwiftUI
import SwiftData

// MARK: - MenuHubView
// 菜单 Tab 的根视图：两张操作卡 + 最近菜单历史预览

struct MenuHubView: View {

    @Query(
        sort: \MenuHistoryModel.date,
        order: .reverse
    ) private var recentMenus: [MenuHistoryModel]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // ── 操作卡区 ──────────────────────────
                Text("今天吃什么？")
                    .font(.title2.bold())
                    .padding(.horizontal)

                HStack(spacing: 14) {
                    NavigationLink(destination: RandomMenuView()) {
                        ActionCard(
                            icon: "dice.fill",
                            title: "骰子推荐",
                            subtitle: "随机生成今日菜单",
                            gradient: [Color.orange, Color.pink]
                        )
                    }
                    NavigationLink(destination: MenuOrderView()) {
                        ActionCard(
                            icon: "checklist",
                            title: "手动点餐",
                            subtitle: "自己选择每道菜",
                            gradient: [Color.blue, Color.indigo]
                        )
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // ── 历史菜单预览 ───────────────────────
                if !recentMenus.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近菜单")
                                .font(.headline)
                            Spacer()
                            NavigationLink("查看全部") {
                                MenuHistoryView()
                            }
                            .font(.subheadline)
                        }
                        .padding(.horizontal)

                        ForEach(recentMenus.prefix(3)) { model in
                            MenuHistoryCard(menu: model)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("今日菜单")
    }
}

// MARK: - ActionCard

private struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .padding(10)
                .background(.white.opacity(0.25), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

// MARK: - MenuHistoryCard (compact preview)

private struct MenuHistoryCard: View {
    let menu: MenuHistoryModel

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f.string(from: menu.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dateLabel)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(menu.dishNames.count) 道菜")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(menu.dishNames.joined(separator: " · "))
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack { MenuHubView() }
}
