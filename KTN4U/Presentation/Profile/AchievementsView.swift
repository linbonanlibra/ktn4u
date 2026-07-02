import SwiftUI

// MARK: - AchievementsView
// 成就墙：已解锁彩色，未解锁灰色 + 解锁日期展示

struct AchievementsView: View {

    @State private var unlocked: [String: Date] = [:]

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 180))]

    var body: some View {
        ScrollView {
            // 进度摘要
            progressSummary
                .padding(.horizontal)
                .padding(.top, 8)

            // 成就网格
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Achievement.all) { achievement in
                    AchievementCell(
                        achievement: achievement,
                        unlockedAt: unlocked[achievement.id]
                    )
                }
            }
            .padding()
        }
        .navigationTitle("成就")
        .task { unlocked = AchievementStore.loadAll() }
    }

    // MARK: Progress Summary

    private var progressSummary: some View {
        let count = unlocked.count
        let total = Achievement.all.count
        let pct   = Int(Double(count) / Double(max(1, total)) * 100)

        return HStack(spacing: 14) {
            Text("\(count)/\(total)")
                .font(.title.bold())
                .monospacedDigit()
            VStack(alignment: .leading, spacing: 4) {
                Text("已解锁成就")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.quaternary).frame(height: 6)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(
                                width: geo.size.width * Double(count) / Double(max(1, total)),
                                height: 6
                            )
                            .animation(.spring(duration: 0.7), value: count)
                    }
                }
                .frame(height: 6)
            }
            Text("\(pct)%")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - AchievementCell

private struct AchievementCell: View {
    let achievement: Achievement
    let unlockedAt: Date?

    private var isUnlocked: Bool { unlockedAt != nil }

    private var dateLabel: String? {
        guard let date = unlockedAt else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy/M/d"
        return f.string(from: date)
    }

    var body: some View {
        VStack(spacing: 10) {
            // Emoji + 未解锁遮罩
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.orange.opacity(0.12) : Color.secondary.opacity(0.08))
                    .frame(width: 60, height: 60)

                Text(achievement.emoji)
                    .font(.system(size: 30))
                    .grayscale(isUnlocked ? 0 : 1)
                    .opacity(isUnlocked ? 1 : 0.35)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .offset(x: 18, y: 18)
                }
            }

            // 标题
            Text(achievement.title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(isUnlocked ? .primary : .secondary)

            // 描述 / 解锁日期
            if let date = dateLabel {
                Text(date)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                Text(achievement.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            isUnlocked
                ? Color.orange.opacity(0.06)
                : Color.secondary.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isUnlocked ? Color.orange.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
}
