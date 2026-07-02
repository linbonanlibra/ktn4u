import SwiftUI

// MARK: - SettingsView
// 设置页面（目前通过 ProfileView 工具卡直接入口，此视图作为可选聚合层）

struct SettingsView: View {
    var body: some View {
        List {
            Section("内容管理") {
                NavigationLink(destination: CategoryEditorView()) {
                    Label("分类管理", systemImage: "folder.badge.gearshape")
                }
            }

            Section("数据") {
                NavigationLink(destination: DataManagementView()) {
                    Label("数据管理", systemImage: "externaldrive.fill")
                }
            }

            Section {
                NavigationLink(destination: aboutContent) {
                    Label("关于 KTN4U", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("设置")
    }

    private var aboutContent: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("👨‍🍳").font(.system(size: 64))
                        Text("KTN4U").font(.title.bold())
                        Text("版本 1.0.0").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            }
            Section("功能") {
                Label("记录菜品，追踪熟练度",    systemImage: "book.fill")
                Label("骰子推荐今日菜单",       systemImage: "dice.fill")
                Label("冰箱食材过期提醒",       systemImage: "refrigerator.fill")
                Label("烹饪打卡，积累经验值",    systemImage: "flame.fill")
            }
        }
        .navigationTitle("关于 KTN4U")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { NavigationStack { SettingsView() } }
