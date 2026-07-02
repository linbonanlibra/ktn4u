# KTN4U — iOS 26 Native 完整开发方案

> 将现有 Flutter 版本重新以 iOS 26 原生（SwiftUI + Swift）实现。  
> 记录时间：2026-07-02

---

## 背景

KTN4U（Kitchen-for-You）是一款个人家庭菜单/菜品 APP，核心用途：
- 记录自己新学的菜品，并追踪每道菜的熟练度（类游戏 XP 升级制）
- 基于自己掌握的菜品手动点餐或生成推荐菜单
- 管理冰箱食材，过期提醒，并在推荐菜单时优先利用冰箱存货

**关键决策：**
- 目标平台：iOS 独占，Target iOS 26
- 熟练度：经验值积累制（类游戏，烹饪打卡 → 积累 XP → 自动升级）
- 数据存储：纯本地，无云同步
- 菜单推荐：纯本地规则算法，预留 AI 接入协议

---

## 一、功能规划

### 1. 菜品库

| 功能 | 细节 |
|------|------|
| 菜品录入 | 名称、嵌套分类、封面图/多图（相机 + 相册）、备注 |
| 烹饪记录（轻量打卡） | 一键记录 → 可选附加照片（相机/相册）+ 可选文字点评；有附图 +3XP，有文字 +2XP |
| 熟练度/XP | 见第 2 节，升级触发全屏动效 |
| 菜品详情 | 展示基础信息 + 历次烹饪记录时间线 + XP 进度条 |
| 搜索与筛选 | 按名称模糊搜索、按分类/等级筛选 |

### 2. 熟练度系统

```
等级    名称    累计 XP 阈值    图标
Lv.0   生手       0           🔪
Lv.1   学徒      10           🍳
Lv.2   熟悉      30           👨‍🍳
Lv.3   熟练      70           ⭐
Lv.4   精通     150           🌟
Lv.5   大师     300           👑
```

**XP 规则：**
- 新增菜品首次解锁 → **+5 XP**（一次性）
- 记录一次烹饪（无附加）→ **+5 XP**
- 记录含照片 → **+3 XP**
- 记录含文字点评 → **+2 XP**
- 单次烹饪记录 XP 上限：**10 XP**

### 3. 分类系统（嵌套二级树）

**预置分类树：**
```
🥩 肉类
  ├── 猪肉
  ├── 牛羊肉
  ├── 鸡鸭鹅
  └── 海鲜水产
🥦 蔬菜
  ├── 叶菜
  ├── 根茎类
  ├── 瓜茄类
  └── 菌菇豆腐
🍜 主食
  ├── 面条 / 饺子
  ├── 米饭 / 粥
  └── 包子 / 饼
🍲 汤品
  ├── 清汤
  └── 浓汤 / 煲汤
🥚 蛋 & 豆制品
🍮 甜点 / 小吃
```

规则：
- 支持在「设置」页面增删改一级/二级分类，调整顺序
- 删除父分类时提示"将移动 N 个菜品到「未分类」"，不强制删除菜品
- `DishCategoryModel(id, name, parentId?, ordinal)` 自关联，`parentId == nil` 表示一级分类

### 4. 冰箱管理

| 功能 | 细节 |
|------|------|
| 食材录入 | 名称、数量、单位（内置常用：克/毫升/个/根/棵/袋）、过期日期 |
| 状态色带 | 过期(红) / ≤3天(橙) / 正常(绿) |
| 推荐联动 | 推荐菜单时按名称模糊匹配冰箱食材，优先推出（暂不做菜品-食材硬关联） |
| Widget | 桌面/锁屏小组件：展示即将过期食材 |

### 5. 菜单规划

| 功能 | 细节 |
|------|------|
| 手动点餐 | 分类浏览 → 勾选 → 底部"已选托盘"→ 保存为今日菜单 |
| 随机推荐 | 参数：餐数（1–6 道）、口味偏好、是否优先用冰箱食材 |
| 菜单历史 | 按日期归档，可复用、可删除 |

**推荐算法优先级（本地规则）：**
1. 冰箱有对应食材的菜 → 优先入选（名称模糊匹配）
2. 避免与近 7 天菜单重复
3. 一级分类均衡（不全是同类）
4. 熟练度 Lv.1+ 的菜（防止选出完全不会做的菜）

### 6. 个人主页

- 菜品总数、各等级分布（Swift Charts 柱状图/饼图）
- 最近烹饪时间线（最近 10 条记录）
- 成就系统（解锁徽章，如：「入门厨师」首次录入 5 道菜）
- 数据备份导出（JSON，通过系统分享面板）

### 7. 设置页面

- 分类管理（增删改顺序、嵌套编辑）
- 关于 & 版本信息
- 数据管理（导出备份 / 清空数据）

---

## 二、设计思路

### 技术选型

| 层次 | 选型 | 说明 |
|------|------|------|
| UI 框架 | **SwiftUI 6** | iOS 26 全新 Liquid Glass 设计语言，`.glassEffect()` 修饰符原生支持 |
| 架构模式 | **MVVM + Clean Architecture** | ViewModel 驱动 View，Domain 层零框架依赖，便于单测 |
| 本地存储 | **SwiftData** | iOS 17+ 稳定，iOS 26 上进一步增强，天然 `@Query` 绑定 SwiftUI |
| 图片存储 | 沙盒 `Documents/DishImages/` | SwiftData 只存文件名，避免 Blob 拖慢查询 |
| 图片选取 | **PhotosUI (`PhotosPicker`)** + **AVFoundation** | 相册用 PhotosPicker，相机用自定义 `CameraView` 封装 |
| 异步 | **Swift Concurrency** | `async/await` + `@MainActor`，无第三方依赖 |
| 图表 | **Swift Charts** | 熟练度分布图 |
| 小组件 | **WidgetKit** | 冰箱过期提醒桌面/锁屏 Widget |
| 依赖管理 | **SPM only** | 零 CocoaPods 配置 |
| 第三方库 | 暂无必要引入 | iOS 26 原生能力已覆盖所有需求 |

### iOS 26 设计语言适配

- 导航栏、Tab Bar 采用 **Liquid Glass** 材质（半透明玻璃）
- 卡片组件使用 `.glassEffect()` 修饰
- 升级动效用 `PhaseAnimator` / `keyframeAnimator` 实现帧动画
- **Haptic Feedback**：升级时 `.notificationFeedback(.success)`，打卡时 `.impactFeedback(.light)`

### 架构分层

```
┌─────────────────────────────────────────┐
│  Presentation（SwiftUI View + ViewModel）│
│  · @Query 直接绑定 SwiftData              │
│  · ViewModel 持有 UseCase 实例            │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  Domain（纯 Swift，零框架依赖）            │
│  · Models（struct 值对象）               │
│  · UseCases（业务规则 + XP 计算）         │
│  · Repository Protocols                 │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  Data（SwiftData 实现层）                 │
│  · @Model 持久化类                       │
│  · Repository 实现                       │
│  · ImageFileStorage                     │
│  · MenuRecommendationStrategy 实现       │
└─────────────────────────────────────────┘
```

### 关键设计决策

| 决策点 | 选择 | 原因 |
|--------|------|------|
| 分类存储 | `DishCategoryModel(id, name, parentId?, ordinal)` 自关联 | 二级树用 parentId=nil 表示一级，简单查询不需要递归 |
| 图片存储 | 沙盒文件 + SwiftData 存文件名 | 避免 Blob 拖慢 SwiftData 查询 |
| XP 计算时机 | 保存 `CookingRecord` 后同步触发 `ProficiencyUseCase` | 保持事务性，升级检测在同一写入流程内 |
| 推荐算法 | `MenuRecommendationStrategy` Protocol | 初版 `LocalRuleMenuStrategy` 落地，未来无缝替换为 AI 版本 |
| 分类预置 | `DefaultCategorySeeder` 首次启动写入，之后完全用户控制 | 不 hardcode 在代码里，保证可编辑 |

---

## 三、模块划分

```
KTN4U/
├── App/
│   ├── KTN4UApp.swift              # 入口 + ModelContainer 注入
│   └── RootTabView.swift           # TabView 主框架（iOS 26 Tab API）
│
├── Domain/
│   ├── Models/
│   │   ├── Dish.swift
│   │   ├── DishCategory.swift      # 支持 parentId，二级树结构
│   │   ├── CookingRecord.swift     # 烹饪记录（XP 来源）
│   │   ├── FridgeItem.swift
│   │   ├── Menu.swift
│   │   ├── Proficiency.swift       # XP 计算 + 等级定义
│   │   └── Achievement.swift
│   ├── UseCases/
│   │   ├── DishUseCase.swift
│   │   ├── ProficiencyUseCase.swift      # XP 计算 + 升级检测（可单测）
│   │   ├── FridgeUseCase.swift
│   │   ├── MenuRecommendationUseCase.swift
│   │   └── AchievementUseCase.swift
│   └── Protocols/
│       ├── DishRepository.swift
│       ├── FridgeRepository.swift
│       ├── CategoryRepository.swift
│       └── MenuRecommendationStrategy.swift  # 算法协议，预留 AI 接入
│
├── Data/
│   ├── SwiftData/
│   │   ├── DishModel.swift
│   │   ├── DishCategoryModel.swift
│   │   ├── CookingRecordModel.swift
│   │   ├── FridgeItemModel.swift
│   │   └── MenuHistoryModel.swift
│   ├── Repositories/
│   │   ├── SDDishRepository.swift
│   │   ├── SDFridgeRepository.swift
│   │   └── SDCategoryRepository.swift
│   ├── Seeding/
│   │   └── DefaultCategorySeeder.swift   # 首次启动写入预置分类树
│   ├── Strategies/
│   │   └── LocalRuleMenuStrategy.swift   # 推荐算法实现
│   └── Storage/
│       └── ImageFileStorage.swift        # 图片沙盒读写
│
├── Presentation/
│   ├── DishBook/
│   │   ├── DishBookView.swift            # 一级分类网格 + 展开二级
│   │   ├── DishListView.swift            # 某二级分类内的菜品列表
│   │   ├── DishDetailView.swift          # 菜品详情 + 打卡入口 + 记录时间线
│   │   ├── AddDishView.swift             # 新增/编辑菜品
│   │   ├── AddCookingRecordView.swift    # 轻量打卡（可选图/文）
│   │   └── DishBookViewModel.swift
│   ├── Menu/
│   │   ├── MenuOrderView.swift           # 手动点餐
│   │   ├── RandomMenuView.swift          # 随机推荐 + 参数面板
│   │   ├── MenuResultView.swift          # 生成结果展示 + 保存
│   │   ├── MenuHistoryView.swift
│   │   └── MenuViewModel.swift
│   ├── Fridge/
│   │   ├── FridgeView.swift
│   │   ├── AddFridgeItemView.swift
│   │   └── FridgeViewModel.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   ├── StatsChartView.swift          # Swift Charts 图表
│   │   ├── AchievementsView.swift
│   │   └── ProfileViewModel.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── CategoryEditorView.swift      # 分类树编辑
│   │   └── SettingsViewModel.swift
│   └── Components/
│       ├── DishCard.swift
│       ├── ProficiencyBar.swift           # XP 进度条 + 等级徽章
│       ├── LevelUpOverlay.swift           # 升级全屏动效
│       ├── CookingRecordRow.swift         # 时间线条目
│       ├── FridgeItemRow.swift
│       ├── CameraView.swift               # 相机封装（AVFoundation）
│       └── EmptyStateView.swift           # 空状态通用组件
│
├── Widget/
│   └── FridgeExpiryWidget.swift
│
└── Tests/
    ├── ProficiencyUseCaseTests.swift
    ├── MenuRecommendationTests.swift
    └── CategoryTreeTests.swift
```

---

## 四、任务拆解

### Phase 0 — 脚手架

- [ ] 创建 Xcode 项目，Target iOS 26，配置 Bundle ID / App Icon 占位
- [ ] 搭建目录结构，建立所有空文件占位
- [ ] 定义 Domain Models（纯 struct，含 Proficiency XP 计算逻辑）
- [ ] 定义所有 Repository / Strategy Protocols
- [ ] 定义 SwiftData `@Model` 类，配置 `ModelContainer`
- [ ] `ImageFileStorage` 实现（存图/读图/删图/清理孤立文件）
- [ ] `DefaultCategorySeeder`：首次启动写入预置分类树
- [ ] `RootTabView`：Tab 框架搭好，各 Tab 先放占位 View

---

### Phase 1 — 菜品库

**分类系统**
- [ ] `DishBookView`：两级分类浏览，一级为 Section，二级为卡片 Grid，Liquid Glass 卡片样式
- [ ] 分类展开/折叠交互，`@Query` 直接驱动

**菜品管理**
- [ ] `DishListView`：某分类内的菜品列表，支持按名称搜索
- [ ] `AddDishView`：名称、嵌套分类 Picker、备注、`PhotosPicker` 多图选取
- [ ] `CameraView`：封装 AVCaptureSession，支持拍照并回调
- [ ] `AddDishView` 相机入口：Sheet 弹出 CameraView，选取后预览

**菜品详情 + 烹饪记录**
- [ ] `DishDetailView`：基础信息展示 + 烹饪记录时间线（`ScrollView` + `LazyVStack`）
- [ ] `AddCookingRecordView`：轻量打卡 Sheet，一个「记录」按钮即可提交，选填照片（PhotosPicker + 相机）和文字
- [ ] `ProficiencyUseCase`：XP 计算 + `didLevelUp(before:after:) -> Bool` 检测
- [ ] `LevelUpOverlay`：升级动效（`PhaseAnimator` 三帧：出现 → 爆炸粒子 → 消散），成功触感
- [ ] `ProficiencyBar`：XP 进度条组件，等级图标 + 数值显示

**单测**
- [ ] `ProficiencyUseCaseTests`：覆盖各 XP 来源、边界升级场景

---

### Phase 2 — 冰箱

- [ ] `FridgeView`：按状态分组（过期/警告/正常），SwipeAction 删除，右上角"+"添加
- [ ] `AddFridgeItemView`：名称、数量输入、单位 Picker（含自定义）、`DatePicker` 过期日期（默认 +7 天）
- [ ] `FridgeUseCase`：到期天数计算、状态枚举 (`expired / warning / normal`)
- [ ] `FridgeItemRow`：色带左边框 + 数量/单位/到期天数展示
- [ ] `FridgeExpiryWidget`：WidgetKit，`SystemSmall` 尺寸展示最近 3 个即将过期食材；锁屏 Widget（`AccessoryRectangular`）

---

### Phase 3 — 菜单规划

**手动点餐**
- [ ] `MenuOrderView`：顶部分类 Tab Scroll + 下方菜品 Grid，底部固定"已选托盘"抽屉（可上滑展开）
- [ ] 托盘交互：选中/取消带弹性动画，托盘展开显示菜品列表
- [ ] 保存为菜单 → 写入 `MenuHistoryModel`

**随机推荐**
- [ ] `RandomMenuView`：参数面板（`Form` 风格）：餐数 Stepper、口味多选 Chip、冰箱优先 Toggle
- [ ] `LocalRuleMenuStrategy`：实现推荐算法（冰箱优先 → 历史去重 → 分类均衡 → XP 过滤），可单测
- [ ] `MenuResultView`：生成结果卡片列表，「换一个」按钮重新推荐，「保存今日菜单」持久化
- [ ] `MenuRecommendationTests`：算法单测

**菜单历史**
- [ ] `MenuHistoryView`：按日期 Section 分组，展开查看菜品，SwipeAction 删除，「复用」按钮

---

### Phase 4 — 个人主页 & 成就

- [ ] `ProfileView`：顶部统计卡片（总菜数/大师数/最近活跃）
- [ ] `StatsChartView`：各等级菜品数量柱状图（Swift Charts `.barMark`）
- [ ] 最近烹饪时间线（最近 10 条 `CookingRecord`，含缩略图）
- [ ] `Achievement` 模型 + `AchievementUseCase`（定义 10 个成就条件，每次数据变更后检查解锁）
- [ ] `AchievementsView`：成就墙，已解锁彩色，未解锁灰色蒙版
- [ ] 数据导出：序列化全部数据为 JSON → `ShareSheet`

---

### Phase 5 — 设置页

- [ ] `SettingsView`：分类管理入口 + 关于 + 数据管理
- [ ] `CategoryEditorView`：
  - 一级分类列表，可新增/重命名/删除/拖动排序（`EditButton` + `.onMove`）
  - 点击一级分类 → 进入二级分类列表，同样支持增删改顺序
  - 删除含菜品的分类时弹出确认 Alert，说明影响
- [ ] 清空数据确认 Alert（双重确认）

---

### Phase 6 — 打磨

- [ ] 全局深色模式适配检查
- [ ] 所有列表/详情空状态（`EmptyStateView` 统一风格）
- [ ] 图片加载骨架屏（`.redacted(reason: .placeholder)`）
- [ ] 全局搜索（`@Query` + `.searchable` 修饰符）
- [ ] App Icon（6 尺寸）+ Launch Screen
- [ ] TestFlight 内测包配置
