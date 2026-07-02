import Testing
import Foundation
@testable import KTN4U

// MARK: - ProficiencyUseCaseTests

@Suite("ProficiencyUseCase")
struct ProficiencyUseCaseTests {

    let useCase = ProficiencyUseCase()

    // 基础：纯打卡无照片无文字 → +5 XP
    @Test func baseCookXP() {
        let record = CookingRecord(id: .init(), dishId: .init(), date: .now,
                                   photoFilenames: [], note: "")
        let newXP = useCase.newXP(currentXP: 0, for: record, isFirstEver: false)
        #expect(newXP == 5)
    }

    // 打卡含照片 → +5+3 = 8 XP
    @Test func cookWithPhotoXP() {
        let record = CookingRecord(id: .init(), dishId: .init(), date: .now,
                                   photoFilenames: ["a.jpg"], note: "")
        let newXP = useCase.newXP(currentXP: 0, for: record, isFirstEver: false)
        #expect(newXP == 8)
    }

    // 打卡含照片+文字 → 10 XP（上限）
    @Test func cookWithPhotoAndNoteXP() {
        let record = CookingRecord(id: .init(), dishId: .init(), date: .now,
                                   photoFilenames: ["a.jpg"], note: "好吃")
        let newXP = useCase.newXP(currentXP: 0, for: record, isFirstEver: false)
        #expect(newXP == 10)
    }

    // 首次解锁加成 → +5 额外
    @Test func firstEverBonus() {
        let record = CookingRecord(id: .init(), dishId: .init(), date: .now,
                                   photoFilenames: [], note: "")
        let newXP = useCase.newXP(currentXP: 0, for: record, isFirstEver: true)
        #expect(newXP == 10)  // 5(base) + 5(first) = 10
    }

    // 升级检测：0→10 应触发升级（生手→学徒）
    @Test func levelUpDetection() {
        #expect(useCase.didLevelUp(from: 9, to: 10) == true)
        #expect(useCase.didLevelUp(from: 8, to: 9) == false)
    }

    // 等级边界正确性
    @Test func levelBoundaries() {
        #expect(ProficiencyLevel.current(xp: 0).level == 0)
        #expect(ProficiencyLevel.current(xp: 9).level == 0)
        #expect(ProficiencyLevel.current(xp: 10).level == 1)
        #expect(ProficiencyLevel.current(xp: 29).level == 1)
        #expect(ProficiencyLevel.current(xp: 30).level == 2)
        #expect(ProficiencyLevel.current(xp: 299).level == 4)
        #expect(ProficiencyLevel.current(xp: 300).level == 5)
        #expect(ProficiencyLevel.current(xp: 999).level == 5)
    }

    // 进度计算：xp=20，在 Lv.1(10)→Lv.2(30) 间，进度 = (20-10)/(30-10) = 0.5
    @Test func progressCalculation() {
        let progress = ProficiencyLevel.progress(xp: 20)
        #expect(abs(progress - 0.5) < 0.001)
    }

    // 大师级进度恒为 1.0
    @Test func masterProgress() {
        #expect(ProficiencyLevel.progress(xp: 300) == 1.0)
        #expect(ProficiencyLevel.progress(xp: 999) == 1.0)
    }
}
