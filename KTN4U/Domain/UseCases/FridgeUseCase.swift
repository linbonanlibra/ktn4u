import Foundation

// MARK: - FridgeUseCase

struct FridgeUseCase: Sendable {
    let repository: any FridgeRepository

    func allItems() async throws -> [FridgeItem] {
        let items = try await repository.fetchAll()
        // 按状态优先级排序：过期 → 警告 → 正常，同状态内按到期日升序
        return items.sorted {
            let order: (FridgeItem.Status) -> Int = { status in
                switch status {
                case .expired: return 0
                case .warning: return 1
                case .normal:  return 2
                }
            }
            if $0.status != $1.status {
                return order($0.status) < order($1.status)
            }
            return $0.expiryDate < $1.expiryDate
        }
    }

    func addItem(_ item: FridgeItem) async throws {
        try await repository.save(item)
    }

    func updateItem(_ item: FridgeItem) async throws {
        try await repository.update(item)
    }

    func deleteItem(id: UUID) async throws {
        try await repository.delete(id: id)
    }

    /// 即将过期（≤3 天，含已过期）的食材，供 Widget 使用
    func urgentItems() async throws -> [FridgeItem] {
        let all = try await repository.fetchAll()
        return all
            .filter { $0.status != .normal }
            .sorted { $0.expiryDate < $1.expiryDate }
    }
}
