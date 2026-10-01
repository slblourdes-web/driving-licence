import Foundation

struct TestAnswerSnapshot: Codable, Identifiable, Hashable {
    var id: String { questionID }
    let position: Int
    let questionID: String
    let category: String
    let questionText: String
    let answers: [AnswerOption]
    let selectedAnswer: String?
    let correctAnswer: String
    let isCorrect: Bool
    let explanation: String
    let source: String?
    let imageName: String?
}

struct TestSessionSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let answers: [TestAnswerSnapshot]
    let correctCount: Int
    let incorrectCount: Int

    var questionCount: Int { answers.count }
    var correctPercentage: Double {
        guard !answers.isEmpty else { return 0 }
        return Double(correctCount) / Double(answers.count) * 100
    }
    var incorrectPercentage: Double {
        guard !answers.isEmpty else { return 0 }
        return Double(incorrectCount) / Double(answers.count) * 100
    }
}
