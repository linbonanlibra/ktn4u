import SwiftUI

// MARK: - MenuResultView
// 菜单结果只读视图：用于从历史菜单导航进来时查看菜品详情
// Phase 3 中 OrderView/RandomView 已内联了生成+保存流程，此视图作为只读入口使用

struct MenuResultView: View {
    let menu: Menu

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "M月d日 HH:mm 的菜单"
        return f.string(from: menu.date)
    }

    var body: some View {
        List {
            Section(header: Text(dateLabel).font(.caption)) {
                ForEach(menu.entries) { entry in
                    HStack(spacing: 12) {
                        if let filename = entry.coverPhotoFilename,
                           let url = ImageFileStorage.url(for: filename) {
                            AsyncImage(url: url) { img in
                                img.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(.quaternary)
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.quaternary)
                                .frame(width: 44, height: 44)
                                .overlay { Image(systemName: "fork.knife").foregroundStyle(.tertiary) }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.dishName)
                                .font(.subheadline.bold())
                            Text(entry.categoryName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("菜单详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MenuResultView(menu: Menu(
            id: UUID(), date: .now,
            entries: [
                MenuEntry(id: UUID(), dishId: UUID(), dishName: "红烧肉",
                          categoryName: "猪肉", coverPhotoFilename: nil),
                MenuEntry(id: UUID(), dishId: UUID(), dishName: "清炒土豆丝",
                          categoryName: "根茎类", coverPhotoFilename: nil),
            ]
        ))
    }
}
