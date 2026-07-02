import SwiftUI

// MARK: - CookingRecordRow
// 烹饪记录时间线条目（Phase 6：布局优化 + 无障碍标签）

struct CookingRecordRow: View {
    let record: CookingRecord

    private var dateString: String {
        record.date.formatted(date: .abbreviated, time: .shortened)
    }

    private var relativeDate: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: record.date, relativeTo: .now)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // ── 时间线竖轨 ────────────────────────────────────────
            timelineTrack

            // ── 内容区 ────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                // 标题行：日期 + XP 徽章
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(relativeDate)
                            .font(.subheadline.bold())
                        Text(dateString)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    // XP 徽章
                    Text("+\(record.xpEarned) XP")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.orange.opacity(0.1), in: Capsule())
                        .contentTransition(.numericText())
                }

                // 文字点评
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 照片缩略图（最多 3 张）
                if !record.photoFilenames.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(record.photoFilenames.prefix(3), id: \.self) { filename in
                            if let url = ImageFileStorage.url(for: filename) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().scaledToFill()
                                            .transition(.opacity)
                                    case .empty:
                                        Rectangle().fill(.quaternary)
                                            .redacted(reason: .placeholder)
                                    default:
                                        Rectangle().fill(.quaternary)
                                    }
                                }
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .accessibilityLabel("烹饪照片")
                            }
                        }

                        if record.photoFilenames.count > 3 {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.quaternary)
                                    .frame(width: 64, height: 64)
                                Text("+\(record.photoFilenames.count - 3)")
                                    .font(.headline.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .padding(.bottom, 20)
        }
        // 无障碍：单一元素描述
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: Timeline Track

    private var timelineTrack: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(.orange)
                .frame(width: 10, height: 10)
                .padding(.top, 3)
                .padding(.leading, 16)

            Rectangle()
                .fill(.quaternary)
                .frame(width: 2)
                .padding(.leading, 20)
        }
        .frame(width: 44)
    }

    private var accessibilityDescription: String {
        var parts = [relativeDate]
        if !record.note.isEmpty { parts.append(record.note) }
        parts.append("获得 \(record.xpEarned) XP")
        if !record.photoFilenames.isEmpty {
            parts.append("含 \(record.photoFilenames.count) 张照片")
        }
        return parts.joined(separator: "，")
    }
}
