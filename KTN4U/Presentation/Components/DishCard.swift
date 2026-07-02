import SwiftUI

// MARK: - DishCard
// 菜品网格卡片：骨架屏加载 + 等级角标 + 无障碍标签

struct DishCard: View {
    let dish: Dish

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 图片区
            coverImage
                .frame(height: 120)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    Text(dish.proficiencyLevel.emoji)
                        .font(.system(size: 14))
                        .padding(6)
                        .background(.thinMaterial, in: Circle())
                        .padding(8)
                }

            // 文字区
            VStack(alignment: .leading, spacing: 6) {
                Text(dish.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                ProficiencyBar(xp: dish.xp, showLabel: false)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        // 无障碍：将整张卡片聚合为单一可访问元素
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("点击查看菜品详情")
    }

    // MARK: Cover Image

    @ViewBuilder
    private var coverImage: some View {
        if let filename = dish.coverPhotoFilename,
           let url = ImageFileStorage.url(for: filename) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                        .transition(.opacity)
                case .failure:
                    placeholderBg
                case .empty:
                    // 骨架屏：系统 shimmer 动画
                    skeletonBg.redacted(reason: .placeholder)
                @unknown default:
                    placeholderBg
                }
            }
        } else {
            placeholderBg
        }
    }

    private var skeletonBg: some View {
        Rectangle().fill(.quaternary)
    }

    private var placeholderBg: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
    }

    private var accessibilityDescription: String {
        let level = dish.proficiencyLevel
        return "\(dish.name)，\(level.name)等级（\(dish.xp) XP）"
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 14) {
        DishCard(dish: Dish(id: UUID(), name: "红烧肉", categoryId: UUID(),
                            coverPhotoFilename: nil, photoFilenames: [],
                            note: "", xp: 0, createdAt: .now))
        DishCard(dish: Dish(id: UUID(), name: "清炒土豆丝", categoryId: UUID(),
                            coverPhotoFilename: nil, photoFilenames: [],
                            note: "", xp: 45, createdAt: .now))
        DishCard(dish: Dish(id: UUID(), name: "鱼香肉丝", categoryId: UUID(),
                            coverPhotoFilename: nil, photoFilenames: [],
                            note: "", xp: 300, createdAt: .now))
    }
    .padding()
}
