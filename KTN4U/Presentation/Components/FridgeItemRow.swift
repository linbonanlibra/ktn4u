import SwiftUI

// MARK: - FridgeItemRow
// 冰箱食材行：左侧色带 + 名称/数量 + 过期胶囊标签

struct FridgeItemRow: View {
    let item: FridgeItem

    // MARK: Computed

    private var statusColor: Color {
        switch item.status {
        case .expired: return .red
        case .warning: return .orange
        case .normal:  return .green
        }
    }

    private var expiryLabel: String {
        let d = item.daysUntilExpiry
        switch d {
        case ..<0:  return "已过期 \(-d) 天"
        case 0:     return "今天到期"
        case 1:     return "明天到期"
        default:    return "\(d) 天后到期"
        }
    }

    private var quantityLabel: String {
        let qty = item.quantity
        // 整数时去掉小数点
        let formatted = qty.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(qty))
            : qty.formatted()
        return "\(formatted) \(item.unit)"
    }

    // MARK: Body

    var body: some View {
        HStack(spacing: 0) {
            // 左侧状态色条
            statusBar

            HStack(spacing: 12) {
                // 名称 + 数量
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.body.bold())
                        .lineLimit(1)

                    Text(quantityLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 过期状态胶囊
                Text(expiryLabel)
                    .font(.caption.bold())
                    .foregroundStyle(item.status == .normal ? .secondary : statusColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        (item.status == .normal ? Color.secondary : statusColor).opacity(0.1),
                        in: Capsule()
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name)，\(quantityLabel)，\(expiryLabel)")
    }

    private var statusBar: some View {
        statusColor
            .frame(width: 4)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 4, bottomLeadingRadius: 4
                )
            )
    }
}

#Preview {
    List {
        FridgeItemRow(item: FridgeItem(
            id: UUID(), name: "五花肉", quantity: 500, unit: "克",
            purchaseDate: .now, expiryDate: .now.addingTimeInterval(-86400 * 2)
        ))
        FridgeItemRow(item: FridgeItem(
            id: UUID(), name: "鸡蛋", quantity: 6, unit: "个",
            purchaseDate: .now, expiryDate: .now.addingTimeInterval(86400 * 2)
        ))
        FridgeItemRow(item: FridgeItem(
            id: UUID(), name: "西红柿", quantity: 3, unit: "个",
            purchaseDate: .now, expiryDate: .now.addingTimeInterval(86400 * 10)
        ))
        FridgeItemRow(item: FridgeItem(
            id: UUID(), name: "豆腐", quantity: 1, unit: "块",
            purchaseDate: .now, expiryDate: .now
        ))
    }
}
