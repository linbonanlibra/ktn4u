import Foundation

// MARK: - LocalRuleMenuStrategy

/// 本地规则推荐算法（初版实现）
/// 优先级：冰箱食材匹配 → 避免近期重复 → 分类均衡 → 熟练度过滤
struct LocalRuleMenuStrategy: MenuRecommendationStrategy {

    func recommend(
        preferences: MenuPreferences,
        from dishes: [Dish],
        categories: [DishCategory],
        fridgeItems: [FridgeItem],
        recentMenus: [Menu]
    ) async -> [Dish] {
        var pool = dishes

        // 1. 熟练度过滤：preferences.allowLowProficiency = false 时排除 Lv.0
        if !preferences.allowLowProficiency {
            let filtered = pool.filter { $0.xp >= ProficiencyLevel.all[1].xpThreshold }
            pool = filtered.isEmpty ? pool : filtered   // 若全是新菜则不过滤，避免空结果
        }

        // 2. 计算近 7 天菜单中出现过的菜品 ID，降低权重
        let recentCutoff = Date.now.addingTimeInterval(-7 * 24 * 3600)
        let recentDishIds = Set(
            recentMenus
                .filter { $0.date >= recentCutoff }
                .flatMap { $0.entries.map(\.dishId) }
        )

        // 3. 冰箱食材名称集合（用于模糊匹配）
        let fridgeNames = Set(fridgeItems.map { $0.name.lowercased() })

        // 4. 给每道菜打分
        let scored: [(dish: Dish, score: Int)] = pool.map { dish in
            var score = 0
            // 冰箱有食材：+10
            if fridgeNames.contains(where: { dish.name.lowercased().contains($0) || $0.contains(dish.name.lowercased()) }) {
                score += preferences.prioritizeFridge ? 10 : 0
            }
            // 近期出现过：-5
            if recentDishIds.contains(dish.id) { score -= 5 }
            // 熟练度越高微加分（避免总选新手菜）
            score += dish.proficiencyLevel.level
            return (dish, score)
        }

        // 5. 按分类做均衡抽取
        //    先按一级分类分组，每组尽量各出一道，凑够 preferences.count
        let topLevelCategories = categories.filter { $0.isTopLevel }
        let childToParent: [UUID: UUID] = Dictionary(
            uniqueKeysWithValues: categories.compactMap { cat -> (UUID, UUID)? in
                guard let pid = cat.parentId else { return nil }
                return (cat.id, pid)
            }
        )

        func parentId(for dish: Dish) -> UUID {
            childToParent[dish.categoryId] ?? dish.categoryId
        }

        // 按一级分类分组
        var groups: [UUID: [(dish: Dish, score: Int)]] = [:]
        for entry in scored {
            let pid = parentId(for: entry.dish)
            groups[pid, default: []].append(entry)
        }
        // 组内按分数降序排列
        groups = groups.mapValues { $0.sorted { $0.score > $1.score } }

        var selected: [Dish] = []
        let target = preferences.count
        var groupKeys = topLevelCategories.map(\.id).filter { groups[$0] != nil }
        var round = 0

        while selected.count < target {
            var madeProgress = false
            for key in groupKeys {
                guard selected.count < target, var group = groups[key], !group.isEmpty else { continue }
                // 同一轮只从每组取一道，确保分类均衡
                if round < group.count {
                    selected.append(group[round].dish)
                    madeProgress = true
                }
            }
            round += 1
            if !madeProgress { break }
        }

        // 若还不够，从剩余高分菜中补齐
        if selected.count < target {
            let selectedIds = Set(selected.map(\.id))
            let remaining = scored
                .filter { !selectedIds.contains($0.dish.id) }
                .sorted { $0.score > $1.score }
                .map(\.dish)
            selected += Array(remaining.prefix(target - selected.count))
        }

        return Array(selected.prefix(target))
    }
}
