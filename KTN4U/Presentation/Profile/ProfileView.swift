import SwiftUI
import SwiftData

// MARK: - ProfileView
// 个人主页：统计概览 + 熟练度图表 + 最近烹饪时间线 + 成就 + 工具

struct ProfileView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ── 新解锁成就提示 ─────────────────────────────────
                if !viewModel.newlyUnlocked.isEmpty {
                    newAchievementBanner
                }

                // ── 英雄区 ─────────────────────────────────────────
                heroSection

                // ── 熟练度分布 ─────────────────────────────────────
                if !viewModel.levelCounts.isEmpty {
                    statsCard
                }

                // ── 最近烹饪时间线 ─────────────────────────────────
                if !viewModel.recentRecords.isEmpty {
                    recentTimelineCard
                }

                // ── 成就进度 ───────────────────────────────────────
                achievementCard

                // ── 工具 ───────────────────────────────────────────
                toolsCard
            }
            .padding()
        }
        .navigationTitle("我的")
        .task { await viewModel.load(context: modelContext) }
    }

    // MARK: - New Achievement Banner

    private var newAchievementBanner: some View {
        HStack(spacing: 12) {
            Text("🎉")
                .font(.title2)
            VStack(alignment: .leading, spacing: 3) {
                Text("解锁了新成就！")
                    .font(.subheadline.bold())
                Text(viewModel.newlyUnlocked.map(\.title).joined(separator: "、"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            NavigationLink(destination: AchievementsView()) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.yellow.opacity(0.4), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        HStack(spacing: 20) {
            // 头像
            Image("AvatarPhoto")
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.regularMaterial, lineWidth: 2))
                .shadow(radius: 4, y: 2)
                .accessibilityLabel("个人头像")

            VStack(alignment: .leading, spacing: 6) {
                Text("我的厨房")
                    .font(.title2.bold())

                // 三项快速统计
                HStack(spacing: 14) {
                    StatPill(value: viewModel.totalDishes, label: "道菜", color: .blue)
                    StatPill(value: viewModel.totalCooks,  label: "次烹饪", color: .orange)
                    StatPill(value: viewModel.menuCount,   label: "份菜单", color: .green)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Stats Card (Chart)

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("熟练度分布")
                .font(.headline)

            StatsChartView(levelCounts: viewModel.levelCounts)

            // 最高等级徽章
            if viewModel.highestLevel > 0 {
                HStack(spacing: 6) {
                    let level = ProficiencyLevel.all[viewModel.highestLevel]
                    Text("最高等级")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(level.emoji + " " + level.name)
                        .font(.caption.bold())
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent Timeline Card

    private var recentTimelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近烹饪")
                .font(.headline)

            ForEach(viewModel.recentRecords.prefix(5), id: \.record.id) { item in
                RecentRecordRow(record: item.record, dishName: item.dishName)
            }

            if viewModel.recentRecords.count > 5 {
                Text("+ \(viewModel.recentRecords.count - 5) 条更早的记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Achievement Card

    private var achievementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("成就")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: AchievementsView()) {
                    HStack(spacing: 4) {
                        Text("查看全部")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            // 进度条
            let progress = Double(viewModel.unlockedCount) / Double(max(1, viewModel.totalAchievements))
            VStack(spacing: 6) {
                HStack {
                    Text("\(viewModel.unlockedCount) / \(viewModel.totalAchievements) 已解锁")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.quaternary).frame(height: 8)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.spring(duration: 0.8), value: progress)
                    }
                }
                .frame(height: 8)
            }

            // 最近解锁的成就缩略图（最多 5 个）
            let recentlyUnlocked = Achievement.all
                .filter { viewModel.unlockedAchievements[$0.id] != nil }
                .sorted {
                    (viewModel.unlockedAchievements[$0.id] ?? .distantPast) >
                    (viewModel.unlockedAchievements[$1.id] ?? .distantPast)
                }
                .prefix(5)

            if !recentlyUnlocked.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(recentlyUnlocked)) { ach in
                        Text(ach.emoji)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(.quaternary, in: Circle())
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tools Card

    private var toolsCard: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: CategoryEditorView()) {
                ToolRow(icon: "folder.badge.gearshape", label: "分类管理", color: .blue)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            NavigationLink(destination: DataManagementView()) {
                ToolRow(icon: "externaldrive.fill", label: "数据管理", color: .orange)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            NavigationLink(destination: AboutView()) {
                ToolRow(icon: "info.circle", label: "关于 KTN4U", color: .gray)
            }
            .buttonStyle(.plain)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

}

// MARK: - Sub-components

private struct StatPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct RecentRecordRow: View {
    let record: CookingRecord
    let dishName: String

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: record.date, relativeTo: .now)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.orange.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay { Text("🍳").font(.body) }

            VStack(alignment: .leading, spacing: 3) {
                Text(dishName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(relativeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if record.xpEarned > 0 {
                        Text("+\(record.xpEarned) XP")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // 照片缩略图
            if let first = record.photoFilenames.first,
               let url = ImageFileStorage.url(for: first) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: { Rectangle().fill(.quaternary) }
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct ToolRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 7))
            Text(label)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - AboutView

private struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("👨‍🍳")
                            .font(.system(size: 64))
                        Text("KTN4U")
                            .font(.title.bold())
                        Text("版本 1.0.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            }

            Section("功能说明") {
                Label("记录菜品，追踪熟练度", systemImage: "book.fill")
                Label("骰子推荐今日菜单", systemImage: "dice.fill")
                Label("冰箱食材过期提醒", systemImage: "refrigerator.fill")
                Label("烹饪打卡，积累经验值", systemImage: "flame.fill")
            }
        }
        .navigationTitle("关于 KTN4U")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { NavigationStack { ProfileView() } }
