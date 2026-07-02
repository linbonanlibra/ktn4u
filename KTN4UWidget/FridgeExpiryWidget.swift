import WidgetKit
import SwiftUI

// MARK: - FridgeExpiryWidget
// 支持三种尺寸：
//   systemSmall          → 桌面小组件，最多 3 条预警
//   systemMedium         → 桌面中组件（默认），最多 6 条预警，左右双栏布局
//   accessoryRectangular → 锁屏矩形组件，单行摘要
//
// 数据来源：主 App 通过 App Group UserDefaults 写入，Widget 每小时读取一次。
// 真机运行需在开发者账号启用 App Group "group.com.ktn4u.app"。

// MARK: - Shared Data Model

struct WidgetFridgeItem: Codable, Identifiable {
    let name: String
    let daysLeft: Int       // 负数 = 已过期

    var id: String { name }
    var isExpired: Bool { daysLeft < 0 }
    var dotColor: Color { isExpired ? .red : .orange }

    var expiryLabel: String {
        switch daysLeft {
        case ..<0:  return "已过期"
        case 0:     return "今天到期"
        case 1:     return "明天"
        default:    return "\(daysLeft) 天"
        }
    }
}

// MARK: - App Group Reader

private enum AppGroupReader {
    static let groupID   = "group.com.ktn4u.app"
    static let widgetKey = "com.ktn4u.widget.urgentItems"

    static func readItems() -> [WidgetFridgeItem] {
        guard
            let defaults = UserDefaults(suiteName: groupID),
            let data     = defaults.data(forKey: widgetKey),
            let items    = try? JSONDecoder().decode([WidgetFridgeItem].self, from: data)
        else { return [] }
        return items
    }
}

// MARK: - Timeline Entry

struct FridgeWidgetEntry: TimelineEntry {
    let date: Date
    let items: [WidgetFridgeItem]

    static let placeholder = FridgeWidgetEntry(
        date: .now,
        items: [
            WidgetFridgeItem(name: "五花肉", daysLeft: 1),
            WidgetFridgeItem(name: "菠菜",   daysLeft: 0),
            WidgetFridgeItem(name: "豆腐",   daysLeft: -1),
            WidgetFridgeItem(name: "牛奶",   daysLeft: 2),
            WidgetFridgeItem(name: "鸡蛋",   daysLeft: 3),
        ]
    )

    static let allGood = FridgeWidgetEntry(date: .now, items: [])
}

// MARK: - Timeline Provider

struct FridgeWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> FridgeWidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (FridgeWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder : makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FridgeWidgetEntry>) -> Void) {
        let entry    = makeEntry()
        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextHour)))
    }

    private func makeEntry() -> FridgeWidgetEntry {
        FridgeWidgetEntry(date: .now, items: AppGroupReader.readItems())
    }
}

// MARK: - Root View

struct FridgeWidgetView: View {
    let entry: FridgeWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - systemSmall（小组件，3 条）

private struct SmallWidgetView: View {
    let entry: FridgeWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            widgetHeader(count: entry.items.count)
                .padding(.bottom, 10)

            if entry.items.isEmpty {
                allGoodView
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(entry.items.prefix(3)) { item in
                        ItemRow(item: item)
                    }
                    if entry.items.count > 3 {
                        Text("还有 \(entry.items.count - 3) 种…")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(14)
        .containerBackground(.regularMaterial, for: .widget)
    }
}

// MARK: - systemMedium（中组件，6 条 / 双栏）

private struct MediumWidgetView: View {
    let entry: FridgeWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            widgetHeader(count: entry.items.count)

            if entry.items.isEmpty {
                allGoodView
                    .frame(maxHeight: .infinity)
            } else {
                itemGrid
            }
        }
        .padding(16)
        .containerBackground(.regularMaterial, for: .widget)
    }

    /// 6 条双栏：左 3 右 3（item 数 ≤ 3 时只用左栏）
    private var itemGrid: some View {
        let leftItems  = Array(entry.items.prefix(3))
        let rightItems = Array(entry.items.dropFirst(3).prefix(3))
        let overflow   = entry.items.count > 6 ? entry.items.count - 6 : 0

        return HStack(alignment: .top, spacing: 16) {
            // 左栏
            VStack(alignment: .leading, spacing: 8) {
                ForEach(leftItems) { item in
                    ItemRow(item: item)
                }
                Spacer(minLength: 0)
            }

            if !rightItems.isEmpty {
                Divider()

                // 右栏
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(rightItems) { item in
                        ItemRow(item: item)
                    }
                    if overflow > 0 {
                        Text("还有 \(overflow) 种…")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - accessoryRectangular（锁屏）

private struct RectangularWidgetView: View {
    let entry: FridgeWidgetEntry

    var body: some View {
        if entry.items.isEmpty {
            Label("冰箱状态正常", systemImage: "checkmark.seal")
                .font(.caption)
                .containerBackground(.clear, for: .widget)
        } else {
            let preview = entry.items.prefix(2).map(\.name).joined(separator: " · ")
            let more    = entry.items.count > 2 ? " +\(entry.items.count - 2)" : ""
            VStack(alignment: .leading, spacing: 3) {
                Label("冰箱预警", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2.bold()).foregroundStyle(.orange)
                Text(preview + more)
                    .font(.caption).lineLimit(1)
            }
            .containerBackground(.clear, for: .widget)
        }
    }
}

// MARK: - Shared Sub-views

private func widgetHeader(count: Int) -> some View {
    HStack(spacing: 4) {
        Image(systemName: "refrigerator.fill").font(.caption2)
        Text("冰箱预警").font(.caption2.bold())
        Spacer()
        if count > 0 {
            Text("\(count)")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(.orange, in: Capsule())
        }
    }
    .foregroundStyle(.secondary)
}

private var allGoodView: some View {
    VStack(spacing: 6) {
        Image(systemName: "checkmark.seal.fill")
            .font(.title2).foregroundStyle(.green)
        Text("食材状态良好")
            .font(.caption).foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
}

private struct ItemRow: View {
    let item: WidgetFridgeItem

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(item.dotColor)
                .frame(width: 6, height: 6)
            Text(item.name)
                .font(.caption.bold())
                .lineLimit(1)
                .layoutPriority(1)
            Spacer(minLength: 0)
            Text(item.expiryLabel)
                .font(.caption2)
                .foregroundStyle(item.isExpired ? .red : .secondary)
        }
    }
}

// MARK: - Widget Configuration

struct FridgeExpiryWidget: Widget {
    let kind = "FridgeExpiryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FridgeWidgetProvider()) { entry in
            FridgeWidgetView(entry: entry)
        }
        .configurationDisplayName("冰箱预警")
        .description("显示即将过期或已过期的食材")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Widget Bundle

@main
struct KTN4UWidgetBundle: WidgetBundle {
    var body: some Widget {
        FridgeExpiryWidget()
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    FridgeExpiryWidget()
} timeline: {
    FridgeWidgetEntry.placeholder
    FridgeWidgetEntry.allGood
}

#Preview(as: .systemMedium) {
    FridgeExpiryWidget()
} timeline: {
    FridgeWidgetEntry.placeholder
    FridgeWidgetEntry.allGood
}

#Preview(as: .accessoryRectangular) {
    FridgeExpiryWidget()
} timeline: {
    FridgeWidgetEntry.placeholder
}
