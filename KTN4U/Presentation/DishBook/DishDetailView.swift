import SwiftUI
import SwiftData

// MARK: - DishDetailView
// @Query 驱动：打卡后 XP 进度条立即更新
// Phase 6 新增：多图横向预览 + 全屏查看器 + 骨架屏

struct DishDetailView: View {
    let dishId: UUID

    @Query private var dishModels: [DishModel]
    @Query private var recordModels: [CookingRecordModel]

    @State private var showAddRecord = false
    @State private var levelUpInfo: ProficiencyLevel?
    @State private var selectedPhotoURL: IdentifiableURL?    // 全屏查看器

    // MARK: Init

    init(dishId: UUID) {
        self.dishId = dishId
        let id = dishId
        _dishModels  = Query(filter: #Predicate<DishModel> { $0.id == id })
        _recordModels = Query(
            filter: #Predicate<CookingRecordModel> { $0.dishId == id },
            sort: \CookingRecordModel.date,
            order: .reverse
        )
    }

    private var dish: Dish?    { dishModels.first?.toDomain() }
    private var records: [CookingRecord] { recordModels.map { $0.toDomain() } }

    // MARK: Body

    var body: some View {
        Group {
            if let dish {
                content(dish)
            } else {
                ContentUnavailableView("菜品不存在", systemImage: "fork.knife.circle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if let level = levelUpInfo {
                LevelUpOverlay(level: level) { levelUpInfo = nil }
            }
        }
        .fullScreenCover(item: $selectedPhotoURL) { wrapper in
            PhotoViewerView(url: wrapper.url)
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func content(_ dish: Dish) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── 封面图 ─────────────────────────────────────────
                coverImage(dish)

                // ── 多图横排预览（有 >1 张图时显示） ───────────────────
                if dish.photoFilenames.count > 1 {
                    photoStrip(dish)
                        .padding(.top, 8)
                }

                // ── 信息区 ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: 16) {
                    Text(dish.name).font(.title.bold())

                    ProficiencyBar(xp: dish.xp)

                    if !dish.note.isEmpty {
                        Text(dish.note)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Button { showAddRecord = true } label: {
                        Label("记录一次烹饪 · +XP", systemImage: "flame.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)
                }
                .padding()

                Divider().padding(.horizontal)

                // ── 烹饪时间线 ──────────────────────────────────────
                cookingTimeline
            }
        }
        .navigationTitle(dish.name)
        .sheet(isPresented: $showAddRecord) {
            AddCookingRecordView(dish: dish) { didLevelUp, newLevel in
                if didLevelUp, let level = newLevel { levelUpInfo = level }
            }
        }
    }

    // MARK: - Cover Image (with skeleton)

    @ViewBuilder
    private func coverImage(_ dish: Dish) -> some View {
        if let filename = dish.coverPhotoFilename,
           let url = ImageFileStorage.url(for: filename) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                        .transition(.opacity)
                case .empty:
                    Rectangle().fill(.quaternary)
                        .overlay(ProgressView())
                        .redacted(reason: .placeholder)
                default:
                    coverPlaceholder
                }
            }
            .frame(maxWidth: .infinity).frame(height: 260)
            .clipped()
            .onTapGesture { selectedPhotoURL = IdentifiableURL(url: url) }
            .accessibilityLabel("菜品封面图，点击全屏查看")
        } else {
            coverPlaceholder
        }
    }

    private var coverPlaceholder: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(maxWidth: .infinity).frame(height: 200)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 48)).foregroundStyle(.tertiary)
            }
    }

    // MARK: - Photo Strip

    private func photoStrip(_ dish: Dish) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(dish.photoFilenames.indices, id: \.self) { i in
                    let filename = dish.photoFilenames[i]
                    if let url = ImageFileStorage.url(for: filename) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().aspectRatio(contentMode: .fill)
                                    .transition(.opacity)
                            case .empty:
                                Rectangle().fill(.quaternary).redacted(reason: .placeholder)
                            default:
                                Rectangle().fill(.quaternary)
                                    .overlay { Image(systemName: "photo").foregroundStyle(.tertiary) }
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture { selectedPhotoURL = IdentifiableURL(url: url) }
                        .accessibilityLabel("第 \(i + 1) 张图，点击全屏")
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Cooking Timeline

    private var cookingTimeline: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("烹饪记录").font(.headline)
                Spacer()
                if !records.isEmpty {
                    Text("共 \(records.count) 次")
                        .font(.caption).foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 4)

            if records.isEmpty {
                Text("还没有烹饪记录，点击上方按钮开始打卡 👆")
                    .font(.subheadline).foregroundStyle(.secondary).padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(records) { record in
                        CookingRecordRow(record: record)
                    }
                }
            }
        }
    }
}

// MARK: - IdentifiableURL (for .fullScreenCover(item:))

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - PhotoViewerView

struct PhotoViewerView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(magnificationGesture)
                            .gesture(dragGesture)
                            .onTapGesture(count: 2) {
                                withAnimation(.spring(duration: 0.35)) {
                                    scale = scale > 1.2 ? 1.0 : 2.0
                                    if scale == 1.0 { offset = .zero }
                                }
                            }
                    case .empty:
                        ProgressView().tint(.white)
                    default:
                        Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { val in
                scale = max(1.0, min(val.magnification, 5.0))
            }
            .onEnded { val in
                if scale < 1.1 {
                    withAnimation(.spring(duration: 0.3)) {
                        scale = 1.0; offset = .zero
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { val in
                if scale > 1.0 { offset = val.translation }
            }
            .onEnded { _ in
                if scale <= 1.0 {
                    withAnimation(.spring(duration: 0.3)) { offset = .zero }
                }
            }
    }
}

#Preview {
    NavigationStack { DishDetailView(dishId: UUID()) }
}
