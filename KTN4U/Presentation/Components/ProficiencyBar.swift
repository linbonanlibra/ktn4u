import SwiftUI

// MARK: - ProficiencyBar
// XP 进度条 + 等级徽章
// Phase 6：.contentTransition(.numericText()) + .symbolEffect + 无障碍标签

struct ProficiencyBar: View {
    let xp: Int
    var showLabel = true

    private var level: ProficiencyLevel { ProficiencyLevel.current(xp: xp) }
    private var progress: Double         { ProficiencyLevel.progress(xp: xp) }
    private var toNext: Int              { ProficiencyLevel.xpToNextLevel(xp: xp) }

    var body: some View {
        HStack(spacing: 8) {

            // 等级 emoji — 等级变化时 bounce
            Text(level.emoji)
                .font(.title3)
                .contentTransition(.symbolEffect(.replace))

            VStack(alignment: .leading, spacing: 4) {
                if showLabel {
                    HStack {
                        Text(level.name)
                            .font(.caption.bold())
                            .contentTransition(.identity)
                        Spacer()
                        if level.level < 5 {
                            HStack(spacing: 2) {
                                Text("还需")
                                Text("\(toNext)")
                                    .contentTransition(.numericText(countsDown: true))
                                    .monospacedDigit()
                                Text("XP")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        } else {
                            Text("已达大师级 🎉")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    .animation(.spring(duration: 0.3), value: xp)
                }

                // 进度条
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.quaternary).frame(height: 6)
                        Capsule()
                            .fill(barGradient)
                            .frame(width: max(0, geo.size.width * progress), height: 6)
                            .animation(.spring(duration: 0.6, bounce: 0.15), value: xp)
                    }
                }
                .frame(height: 6)
            }
        }
        // 无障碍：汇总描述
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Helpers

    private var barGradient: LinearGradient {
        let colors: [Color] = switch level.level {
        case 0: [.gray.opacity(0.6), .gray]
        case 1: [.blue.opacity(0.7), .blue]
        case 2: [.green.opacity(0.7), .green]
        case 3: [.yellow.opacity(0.8), .orange]
        case 4: [.orange.opacity(0.8), .red]
        case 5: [.red, .pink]
        default: [.gray, .gray]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    private var accessibilityLabel: String {
        if level.level < 5 {
            return "\(level.name)，\(xp) XP，距 \(ProficiencyLevel.all[level.level + 1].name) 还差 \(toNext) XP"
        }
        return "大师级，\(xp) XP"
    }
}

#Preview {
    VStack(spacing: 20) {
        ProficiencyBar(xp: 0)
        ProficiencyBar(xp: 15)
        ProficiencyBar(xp: 45)
        ProficiencyBar(xp: 300)
    }
    .padding()
}
