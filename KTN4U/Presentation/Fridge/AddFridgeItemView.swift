import SwiftUI

// MARK: - AddFridgeItemView
// 支持「添加」和「编辑」两种模式：
//   existingItem == nil → 添加
//   existingItem != nil → 编辑（预填表单）

struct AddFridgeItemView: View {

    var existingItem: FridgeItem? = nil
    /// 完成回调：无论新增还是编辑，均回传最终的 FridgeItem
    var onComplete: (FridgeItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name       = ""
    @State private var quantityStr = "1"
    @State private var unit       = FridgeItem.commonUnits[0]
    @State private var customUnit  = ""
    @State private var useCustomUnit = false
    @State private var expiryDate = Date.now.addingTimeInterval(7 * 24 * 3600)

    // 编辑模式下保留原始 id、purchaseDate
    private var isEditing: Bool { existingItem != nil }
    private var effectiveUnit: String { useCustomUnit ? customUnit : unit }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(quantityStr) ?? 0) > 0 &&
        (!useCustomUnit || !customUnit.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                quantitySection
                expirySection
            }
            .navigationTitle(isEditing ? "编辑食材" : "添加食材")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "保存" : "添加") { commitSave() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { prefill() }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("食材名称") {
            TextField("例：五花肉、菠菜、鸡蛋", text: $name)
                .autocorrectionDisabled()
        }
    }

    private var quantitySection: some View {
        Section("数量与单位") {
            HStack(spacing: 12) {
                // 数量输入
                TextField("数量", text: $quantityStr)
                    .keyboardType(.decimalPad)
                    .frame(width: 72)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

                Divider()

                // 单位选择
                if useCustomUnit {
                    TextField("自定义单位", text: $customUnit)
                        .autocorrectionDisabled()
                } else {
                    Picker("单位", selection: $unit) {
                        ForEach(FridgeItem.commonUnits, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                Spacer()

                Toggle("自定义", isOn: $useCustomUnit.animation())
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
        }
    }

    private var expirySection: some View {
        Section {
            DatePicker(
                "过期日期",
                selection: $expiryDate,
                in: Date.now...,
                displayedComponents: .date
            )

            // 快捷预设
            VStack(alignment: .leading, spacing: 8) {
                Text("快捷设置")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(ExpiryPreset.allCases) { preset in
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                expiryDate = preset.date
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(preset.label)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    isSelected(preset)
                                        ? Color.accentColor
                                        : Color.secondary.opacity(0.15),
                                    in: Capsule()
                                )
                                .foregroundStyle(
                                    isSelected(preset) ? .white : .primary
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(duration: 0.2), value: expiryDate)
                    }
                }
            }
        } header: {
            Text("保质期")
        }
    }

    // MARK: - Helpers

    private func prefill() {
        guard let item = existingItem else { return }
        name         = item.name
        quantityStr  = item.quantity.formatted()
        expiryDate   = item.expiryDate
        if FridgeItem.commonUnits.contains(item.unit) {
            unit = item.unit
            useCustomUnit = false
        } else {
            customUnit    = item.unit
            useCustomUnit = true
        }
    }

    private func commitSave() {
        let result = FridgeItem(
            id:           existingItem?.id ?? UUID(),
            name:         name.trimmingCharacters(in: .whitespaces),
            quantity:     Double(quantityStr) ?? 1,
            unit:         effectiveUnit,
            purchaseDate: existingItem?.purchaseDate ?? .now,
            expiryDate:   expiryDate
        )
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onComplete(result)
        dismiss()
    }

    private func isSelected(_ preset: ExpiryPreset) -> Bool {
        Calendar.current.isDate(expiryDate, inSameDayAs: preset.date)
    }
}

// MARK: - Expiry Presets

private enum ExpiryPreset: CaseIterable, Identifiable {
    case tomorrow, threeDays, oneWeek, oneMonth

    var id: Self { self }

    var label: String {
        switch self {
        case .tomorrow:  return "明天"
        case .threeDays: return "3天"
        case .oneWeek:   return "1周"
        case .oneMonth:  return "1个月"
        }
    }

    var date: Date {
        let cal = Calendar.current
        switch self {
        case .tomorrow:  return cal.date(byAdding: .day,   value: 1,  to: .now)!
        case .threeDays: return cal.date(byAdding: .day,   value: 3,  to: .now)!
        case .oneWeek:   return cal.date(byAdding: .day,   value: 7,  to: .now)!
        case .oneMonth:  return cal.date(byAdding: .month, value: 1,  to: .now)!
        }
    }
}

#Preview {
    AddFridgeItemView { _ in }
}
