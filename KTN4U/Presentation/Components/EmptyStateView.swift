import SwiftUI

// MARK: - EmptyStateView
// 统一空状态展示组件

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "开始"

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        } actions: {
            if let action {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    EmptyStateView(
        icon: "book.closed",
        title: "还没有菜品",
        message: "点击右上角 + 开始录入第一道菜"
    )
}
