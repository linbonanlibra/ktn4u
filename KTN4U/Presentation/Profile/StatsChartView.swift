import SwiftUI
import Charts

// MARK: - StatsChartView
// 各等级菜品数量柱状图，带数值标注和渐入动画

struct StatsChartView: View {
    let levelCounts: [Int: Int]

    @State private var animateBars = false

    private var maxCount: Int {
        levelCounts.values.max() ?? 1
    }

    var body: some View {
        Chart {
            ForEach(ProficiencyLevel.all, id: \.level) { level in
                let count = levelCounts[level.level] ?? 0
                BarMark(
                    x: .value("等级", level.emoji),
                    y: .value("菜品数", animateBars ? count : 0)
                )
                .foregroundStyle(barGradient(for: level.level))
                .cornerRadius(5)
                .annotation(position: .top, alignment: .center) {
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .opacity(animateBars ? 1 : 0)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let intVal = value.as(Int.self), intVal > 0 {
                    AxisGridLine(stroke: StrokeStyle(dash: [3]))
                        .foregroundStyle(.quaternary)
                    AxisValueLabel { Text("\(intVal)") }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let str = value.as(String.self) {
                        Text(str).font(.title3)
                    }
                }
            }
        }
        .frame(height: 180)
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.2).delay(0.1)) {
                animateBars = true
            }
        }
        .onChange(of: levelCounts) {
            animateBars = false
            withAnimation(.spring(duration: 0.5)) { animateBars = true }
        }
    }

    private func barGradient(for level: Int) -> LinearGradient {
        let colors: [Color] = switch level {
        case 0: [.gray.opacity(0.6), .gray]
        case 1: [.blue.opacity(0.7), .blue]
        case 2: [.green.opacity(0.7), .green]
        case 3: [.yellow.opacity(0.7), .yellow]
        case 4: [.orange.opacity(0.7), .orange]
        case 5: [.red.opacity(0.7), .red]
        default: [.gray, .gray]
        }
        return LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top)
    }
}

#Preview {
    StatsChartView(levelCounts: [0: 2, 1: 5, 2: 4, 3: 3, 4: 1, 5: 1])
        .padding()
}
