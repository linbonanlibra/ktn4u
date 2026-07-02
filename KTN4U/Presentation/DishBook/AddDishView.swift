import SwiftUI
import PhotosUI

// MARK: - AddDishView
// Phase 1 实现：新建/编辑菜品

struct AddDishView: View {
    var preselectedCategoryId: UUID? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var note = ""
    @State private var selectedCategoryId: UUID? = nil
    @State private var topCategories: [DishCategory] = []
    @State private var childrenByParent: [UUID: [DishCategory]] = [:]
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var isSaving = false

    private var allLeafCategories: [DishCategory] {
        var result: [DishCategory] = []
        for parent in topCategories {
            let children = childrenByParent[parent.id] ?? []
            if children.isEmpty {
                result.append(parent)
            } else {
                result.append(contentsOf: children)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("菜品名称（必填）", text: $name)

                    Picker("所属分类", selection: $selectedCategoryId) {
                        Text("请选择").tag(Optional<UUID>.none)
                        ForEach(allLeafCategories) { cat in
                            Text(cat.name).tag(Optional(cat.id))
                        }
                    }
                }

                Section("备注") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }

                Section("照片") {
                    photoPickerRow
                    if !selectedImages.isEmpty {
                        photoPreviewRow
                    }
                }
            }
            .navigationTitle("新增菜品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { Task { await saveDish() } }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategoryId == nil || isSaving)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    if let img = image { selectedImages.append(img) }
                }
            }
            .task { await loadCategories() }
            .onAppear { selectedCategoryId = preselectedCategoryId }
        }
    }

    private var photoPickerRow: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 9,
                         matching: .images) {
                Label("从相册选取", systemImage: "photo.on.rectangle")
            }
            .onChange(of: selectedPhotoItems) { _, items in
                Task { await loadSelectedPhotos(items) }
            }

            Button {
                showCamera = true
            } label: {
                Label("拍照", systemImage: "camera")
            }
        }
    }

    private var photoPreviewRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedImages.indices, id: \.self) { idx in
                    Image(uiImage: selectedImages[idx])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                selectedImages.remove(at: idx)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, .black)
                                    .padding(4)
                            }
                        }
                }
            }
        }
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                images.append(img)
            }
        }
        selectedImages = images
    }

    private func loadCategories() async {
        let repo = SDCategoryRepository(context: modelContext)
        let all = (try? await repo.fetchAll()) ?? []
        topCategories = all.filter { $0.isTopLevel }.sorted { $0.ordinal < $1.ordinal }
        childrenByParent = Dictionary(grouping: all.filter { !$0.isTopLevel }, by: { $0.parentId! })
    }

    private func saveDish() async {
        guard let catId = selectedCategoryId else { return }
        isSaving = true
        defer { isSaving = false }

        var filenames: [String] = []
        for image in selectedImages {
            if let name = try? ImageFileStorage.save(image) { filenames.append(name) }
        }

        let dish = Dish(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            categoryId: catId,
            coverPhotoFilename: filenames.first,
            photoFilenames: filenames,
            note: note,
            xp: 0,
            createdAt: .now
        )
        let repo = SDDishRepository(context: modelContext)
        try? await repo.save(dish)
        dismiss()
    }
}

#Preview {
    AddDishView()
}
