import Foundation
import SwiftData

@Model
final class StudyTestRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var correctCount: Int
    var incorrectCount: Int
    @Relationship(deleteRule: .cascade) var answers: [TestAnswerRecord]

    init(id: UUID = UUID(), date: Date = .now, correctCount: Int = 0, incorrectCount: Int = 0, answers: [TestAnswerRecord] = []) {
        self.id = id
        self.date = date
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.answers = answers
    }

    var questionCount: Int { answers.count }

    var correctPercentage: Double {
        guard questionCount > 0 else { return 0 }
        return Double(correctCount) / Double(questionCount) * 100
    }

    var incorrectPercentage: Double {
        guard questionCount > 0 else { return 0 }
        return Double(incorrectCount) / Double(questionCount) * 100
    }

    var snapshot: TestSessionSnapshot {
        let questionSnapshots = answers
            .sorted { $0.position < $1.position }
            .map { answer in
                TestAnswerSnapshot(
                    position: answer.position,
                    questionID: answer.questionID,
                    category: answer.category,
                    questionText: answer.questionText,
                    answers: answer.answers,
                    selectedAnswer: answer.selectedAnswer,
                    correctAnswer: answer.correctAnswer,
                    isCorrect: answer.isCorrect,
                    explanation: answer.explanation,
                    source: answer.source,
                    imageName: answer.imageName
                )
            }
        return TestSessionSnapshot(
            id: id,
            date: date,
            answers: questionSnapshots,
            correctCount: correctCount,
            incorrectCount: incorrectCount
        )
    }
}

@Model
final class TestAnswerRecord {
    @Attribute(.unique) var id: UUID
    var position: Int
    var questionID: String
    var category: String
    var questionText: String
    var answersData: Data
    var selectedAnswer: String?
    var correctAnswer: String
    var explanation: String
    var source: String?
    var imageName: String?

    init(snapshot: TestAnswerSnapshot) throws {
        id = UUID()
        position = snapshot.position
        questionID = snapshot.questionID
        category = snapshot.category
        questionText = snapshot.questionText
        answersData = try JSONEncoder().encode(snapshot.answers)
        selectedAnswer = snapshot.selectedAnswer
        correctAnswer = snapshot.correctAnswer
        explanation = snapshot.explanation
        source = snapshot.source
        imageName = snapshot.imageName
    }

    var answers: [AnswerOption] {
        (try? JSONDecoder().decode([AnswerOption].self, from: answersData)) ?? []
    }

    var isCorrect: Bool { selectedAnswer == correctAnswer }
}

@Model
final class QuestionStatisticRecord {
    @Attribute(.unique) var questionID: String
    var timesAnswered: Int
    var correctCount: Int
    var incorrectCount: Int
    var lastAnsweredAt: Date?

    init(questionID: String, timesAnswered: Int = 0, correctCount: Int = 0, incorrectCount: Int = 0, lastAnsweredAt: Date? = nil) {
        self.questionID = questionID
        self.timesAnswered = timesAnswered
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.lastAnsweredAt = lastAnsweredAt
    }
}
