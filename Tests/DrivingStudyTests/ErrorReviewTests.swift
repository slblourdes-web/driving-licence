import XCTest
import SwiftData
@testable import DrivingStudy

final class ErrorReviewTests: XCTestCase {
    func testGeneratorPrioritizesFrequentMistakesAndKeepsPreviouslyMissedQuestions() {
        let questions = makeQuestions(count: 3)
        let statistics = [
            QuestionStatistics(questionID: "question-0", timesAnswered: 6, correctCount: 2, incorrectCount: 4),
            QuestionStatistics(questionID: "question-1", timesAnswered: 5, correctCount: 2, incorrectCount: 3),
            QuestionStatistics(questionID: "question-2", timesAnswered: 0, correctCount: 0, incorrectCount: 0)
        ]

        let selected = ErrorReviewGenerator().selectQuestions(from: questions, statistics: statistics)

        XCTAssertEqual(selected.map(\.id), ["question-0", "question-1"])
    }

    @MainActor
    func testViewModelChecksAndRecordsAnAnswerOnlyOnce() throws {
        let container = try makeInMemoryContainer()
        let question = makeQuestions(count: 1)[0]
        let statistic = QuestionStatisticRecord(questionID: question.id, timesAnswered: 1, correctCount: 0, incorrectCount: 1)
        container.mainContext.insert(statistic)
        try container.mainContext.save()
        let viewModel = ErrorReviewViewModel(questions: [question])

        viewModel.selectAnswer("A")
        XCTAssertTrue(try viewModel.checkAnswer(in: container.mainContext))
        XCTAssertTrue(viewModel.hasCheckedAnswer)
        XCTAssertTrue(viewModel.checkedAnswerIsCorrect)
        XCTAssertFalse(try viewModel.checkAnswer(in: container.mainContext))
        XCTAssertEqual(statistic.timesAnswered, 2)
        XCTAssertEqual(statistic.correctCount, 1)
        XCTAssertEqual(statistic.incorrectCount, 1)
    }

    @MainActor
    func testRecordingCorrectPracticeAnswerDoesNotErasePreviousErrors() throws {
        let container = try makeInMemoryContainer()
        let statistic = QuestionStatisticRecord(questionID: "question-0", timesAnswered: 4, correctCount: 1, incorrectCount: 3)
        container.mainContext.insert(statistic)
        try container.mainContext.save()

        try ErrorReviewPersistenceService().recordAnswer(
            questionID: "question-0",
            isCorrect: true,
            at: Date(timeIntervalSince1970: 1_800_000_000),
            in: container.mainContext
        )

        XCTAssertEqual(statistic.timesAnswered, 5)
        XCTAssertEqual(statistic.correctCount, 2)
        XCTAssertEqual(statistic.incorrectCount, 3)
        XCTAssertEqual(statistic.lastAnsweredAt, Date(timeIntervalSince1970: 1_800_000_000))
        XCTAssertEqual(ErrorReviewGenerator().selectQuestions(
            from: makeQuestions(count: 1),
            statistics: [QuestionStatistics(questionID: statistic.questionID, timesAnswered: statistic.timesAnswered, correctCount: statistic.correctCount, incorrectCount: statistic.incorrectCount)]
        ).map(\.id), ["question-0"])
    }

    @MainActor
    func testRecordingPracticeErrorIncrementsErrorStatistics() throws {
        let container = try makeInMemoryContainer()
        let statistic = QuestionStatisticRecord(questionID: "question-0", timesAnswered: 1, correctCount: 1, incorrectCount: 0)
        container.mainContext.insert(statistic)
        try container.mainContext.save()

        try ErrorReviewPersistenceService().recordAnswer(questionID: "question-0", isCorrect: false, in: container.mainContext)

        XCTAssertEqual(statistic.timesAnswered, 2)
        XCTAssertEqual(statistic.correctCount, 1)
        XCTAssertEqual(statistic.incorrectCount, 1)
    }

    @MainActor
    private func makeInMemoryContainer() throws -> ModelContainer {
        try ModelContainer(
            for: StudyTestRecord.self,
            TestAnswerRecord.self,
            QuestionStatisticRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeQuestions(count: Int) -> [StudyQuestion] {
        (0..<count).map { index in
            StudyQuestion(
                id: "question-\(index)",
                category: "DEMO - Repaso",
                question: "Pregunta de prueba \(index)",
                answers: [
                    AnswerOption(id: "A", text: "Respuesta A"),
                    AnswerOption(id: "B", text: "Respuesta B"),
                    AnswerOption(id: "C", text: "Respuesta C")
                ],
                correctAnswer: "A",
                explanation: "Explicación de prueba",
                source: nil,
                imageName: nil
            )
        }
    }
}
