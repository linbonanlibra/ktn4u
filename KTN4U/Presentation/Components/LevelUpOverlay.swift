import SwiftUI

// MARK: - LevelUpOverlay
// 升级全屏动效：keyframeAnimator 三阶段 — 弹入 → 脉冲庆祝 → 渐出

struct LevelUpOverlay: View {
    let level: ProficiencyLevel
    var onDismiss: () -> Void

    @State private var animTrigger = false
    @State private var isDismissing = false

    // MARK: Animation Value Types

    private struct CardValues {
        var scale: CGFloat = 0.5
        var opacity: Double = 0
        var yOffset: CGFloat = 50
    }

    private struct EmojiValues {
        var scale: CGFloat = 0.3
        var rotation: Double = -15
    }

    // MARK: Body

    var body: some View {
        ZStack {
            // 遮罩背景
            Color.black
                .opacity(isDismissing ? 0 : 0.65)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.3), value: isDismissing)
                .onTapGesture { triggerDismiss() }

            // 卡片内容
            VStack(spacing: 24) {
                // 大 emoji：弹入 + 双跳脉冲
                Text(level.emoji)
                    .font(.system(size: 88))
                    .keyframeAnimator(
                        initialValue: EmojiValues(),
                        trigger: animTrigger
                    ) { view, val in
                        view
                            .scaleEffect(val.scale)
                            .rotationEffect(.degrees(val.rotation))
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            LinearKeyframe(0.3, duration: 0)
                            SpringKeyframe(1.25, duration: 0.35,
                                           spring: .bouncy(duration: 0.35, extraBounce: 0.35))
                            SpringKeyframe(1.0, duration: 0.2)
                            SpringKeyframe(1.1, duration: 0.12)   // 第一下脉冲
                            SpringKeyframe(1.0, duration: 0.1)
                            SpringKeyframe(1.06, duration: 0.1)   // 第二下脉冲
                            SpringKeyframe(1.0, duration: 0.1)
                        }
                        KeyframeTrack(\.rotation) {
                            LinearKeyframe(-15, duration: 0)
                            SpringKeyframe(8, duration: 0.25, spring: .bouncy)
                            SpringKeyframe(0, duration: 0.2)
                        }
                    }

                // 文字区
                VStack(spacing: 8) {
                    Text("升级了！")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text(level.emoji)
                        Text(level.name)
                    }
                    .font(.title2.bold())
                    .foregroundStyle(levelAccentColor)

                    Text(levelMotivation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // 确认按钮
                Button("继续加油！") { triggerDismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(levelAccentColor)
                    .controlSize(.large)
            }
            .padding(32)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            // 卡片整体：弹入动效
            .keyframeAnimator(
                initialValue: CardValues(),
                trigger: animTrigger
            ) { view, val in
                view
                    .scaleEffect(val.scale)
                    .opacity(val.opacity)
                    .offset(y: val.yOffset)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.5, duration: 0)
                    SpringKeyframe(1.0, duration: 0.45,
                                   spring: .bouncy(duration: 0.45, extraBounce: 0.1))
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0, duration: 0)
                    LinearKeyframe(1, duration: 0.12)
                }
                KeyframeTrack(\.yOffset) {
                    LinearKeyframe(50, duration: 0)
                    SpringKeyframe(0, duration: 0.45, spring: .bouncy)
                }
            }
        }
        .onAppear {
            // 触感反馈
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // 下一 runloop 触发 keyframe，确保初始帧已渲染
            DispatchQueue.main.async { animTrigger = true }
        }
    }

    // MARK: Helpers

    private func triggerDismiss() {
        isDismissing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onDismiss() }
    }

    private var levelAccentColor: Color {
        switch level.level {
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .accentColor
        }
    }

    private var levelMotivation: String {
        switch level.level {
        case 1: return "初入厨房，勇气可嘉！"
        case 2: return "手艺渐长，继续练习！"
        case 3: return "越来越稳了，加油！"
        case 4: return "几乎已是一代厨艺高手！"
        case 5: return "恭喜达到大师境界！👑"
        default: return ""
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        LevelUpOverlay(level: ProficiencyLevel.all[3]) {}
    }
}
