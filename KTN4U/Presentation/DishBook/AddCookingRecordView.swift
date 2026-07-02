import SwiftUI
import PhotosUI

// MARK: - AddCookingRecordView
// Phase 1 实现：轻量打卡 Sheet（照片和文字均可选）

struct AddCookingRecordView: View {
    let dish: Dish
    /// 回调：(升级了吗, 新等级)
    var onComplete: (Bool, ProficiencyLevel?) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var note = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var isSaving = false

    /// 预计本次可获得的 XP（实时计算，给用户即时反馈）
    private var previewXP: Int {
        var xp = 5
        if !selectedImages.isEmpty { xp += 3 }
        if !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { xp += 2 }
        return min(xp, 10)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // XP 预览
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("本次可获得 \(previewXP) XP")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("今天做了什么？（选填）") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("写点心得、记录一下味道…")
                                    .foregroundStyle(.placeholder)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("添加照片（选填，+3 XP）") {
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 4,
                                     matching: .images) {
                            Label("相册", systemImage: "photo.on.rectangle")
                        }
                        .onChange(of: selectedPhotoItems) { _, items in
                            Task { await loadPhotos(items) }
                        }

                        Button { showCamera = true } label: {
                            Label("相机", systemImage: "camera")
                        }
                    }

                    if !selectedImages.isEmpty {
                        photoStrip
                    }
                }
            }
            .navigationTitle("烹饪打卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "保存中…" : "记录！") {
                        Task { await saveRecord() }
                    }
                    .disabled(isSaving)
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { img in
                    if let img { selectedImages.append(img) }
                }
            }
        }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedImages.indices, id: \.self) { idx in
                    Image(uiImage: selectedImages[idx])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topTrailing) {
                            Button { selectedImages.remove(at: idx) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, .black)
                                    .padding(3)
                            }
                        }
                }
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) { images.append(img) }
        }
        selectedImages = images
    }

    private func saveRecord() async {
        isSaving = true
        defer { isSaving = false }

        var filenames: [String] = []
        for image in selectedImages {
            if let name = try? ImageFileStorage.save(image) { filenames.append(name) }
        }

        let record = CookingRecord(
            id: UUID(),
            dishId: dish.id,
            date: .now,
            photoFilenames: filenames,
            note: note
        )

        let repo = SDDishRepository(context: modelContext)
        let result = try? await repo.addCookingRecord(record)
        let didLevelUp = result?.didLevelUp ?? false
        let newLevel: ProficiencyLevel? = didLevelUp ? ProficiencyLevel.current(xp: result?.newXP ?? 0) : nil

        // 轻触感反馈
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
        onComplete(didLevelUp, newLevel)
    }
}
