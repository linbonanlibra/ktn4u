import UIKit
import Foundation

// MARK: - ImageFileStorage

/// 菜品图片的沙盒文件读写工具
/// 图片统一存于 Documents/DishImages/，SwiftData 只存文件名
struct ImageFileStorage: Sendable {

    // MARK: Private

    private static let dirName = "DishImages"

    private static var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent(dirName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: Public API

    /// 保存 UIImage，返回写入的文件名（含扩展名）
    static func save(_ image: UIImage, compressionQuality: CGFloat = 0.85) throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw ImageStorageError.compressionFailed
        }
        try data.write(to: url, options: .atomic)
        return filename
    }

    /// 读取图片（文件不存在返回 nil）
    static func load(_ filename: String) -> UIImage? {
        guard !filename.isEmpty else { return nil }
        let url = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// 删除单张图片
    static func delete(_ filename: String) {
        guard !filename.isEmpty else { return }
        let url = directory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    /// 批量删除
    static func delete(_ filenames: [String]) {
        filenames.forEach { delete($0) }
    }

    /// 返回图片在磁盘上的 URL（用于 AsyncImage 等）
    static func url(for filename: String) -> URL? {
        guard !filename.isEmpty else { return nil }
        return directory.appendingPathComponent(filename)
    }

    // MARK: Error

    enum ImageStorageError: Error, LocalizedError {
        case compressionFailed

        var errorDescription: String? {
            switch self {
            case .compressionFailed: return "图片压缩失败"
            }
        }
    }
}
