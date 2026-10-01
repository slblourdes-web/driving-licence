import XCTest
import SwiftData
@testable import DrivingStudy

final class TestEvaluatorTests: XCTestCase {
    func testEightOfTenProducesEightyPercent() throws {
        let questions = makeQuestions(count: 10)
        let result = try TestEvaluator().evaluate(questions: questions, selectedAnswers: answers(for: questions, wrongCount: 2))

        XCTAssertEqual(result.correctCount, 8)
        XCTAssertEqual(result.incorrectCount, 2)
        XCTAssertEqual(result.correctPercentage, 80, accuracy: 0.0001)
        XCTAssertEqual(result.incorrectPercentage, 20, accuracy: 0.0001)
    }

    func testTwentyOneOfTwentyFiveProducesEightyFourPercent() throws {
        let questions = makeQuestions(count: 25)
        let result = try TestEvaluator().evaluate(questions: questions, selectedAnswers: answers(for: questions, wrongCount: 4))

        XCTAssertEqual(result.correctCount, 21)
        XCTAssertEqual(result.correctPercentage, 84, accuracy: 0.0001)
    }

    func testEvaluatorIdentifiesCorrectAndIncorrectAnswers() throws {
        let questions = makeQuestions(count: 2)
        let result = try TestEvaluator().evaluate(questions: questions, selectedAnswers: ["question-0": "A", "question-1": "C"])

        XCTAssertTrue(result.answers[0].isCorrect)
        XCTAssertFalse(result.answers[1].isCorrect)
        XCTAssertEqual(result.correctCount, 1)
        XCTAssertEqual(result.incorrectCount, 1)
    }

    func testSnapshotRetainsQuestionContentAndSelectedAnswer() throws {
        let question = makeQuestions(count: 1)[0]
        let result = try TestEvaluator().evaluate(questions: [question], selectedAnswers: [question.id: "B"])
        let snapshot = try XCTUnwrap(result.answers.first)

        XCTAssertEqual(snapshot.questionID, question.id)
        XCTAssertEqual(snapshot.position, 0)
        XCTAssertEqual(snapshot.category, question.category)
        XCTAssertEqual(snapshot.questionText, question.question)
        XCTAssertEqual(snapshot.answers, question.answers)
        XCTAssertEqual(snapshot.selectedAnswer, "B")
        XCTAssertEqual(snapshot.correctAnswer, "A")
        XCTAssertFalse(snapshot.isCorrect)
        XCTAssertEqual(snapshot.explanation, question.explanation)
        XCTAssertEqual(snapshot.source, question.source)
        XCTAssertEqual(snapshot.imageName, question.imageName)
    }

    func testCorrectAndIncorrectCountsAlwaysEqualTotal() throws {
        let questions = makeQuestions(count: 25)
        let result = try TestEvaluator().evaluate(questions: questions, selectedAnswers: answers(for: questions, wrongCount: 9))

        XCTAssertEqual(result.correctCount + result.incorrectCount, result.questionCount)
    }

    @MainActor
    func testSavingUpdatesQuestionStatisticsAndLastAnsweredDate() throws {
        let container = try makeInMemoryContainer()
        let questions = makeQuestions(count: 2)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let result = try TestEvaluator().evaluate(
            questions: questions,
            selectedAnswers: ["question-0": "A", "question-1": "B"],
            date: date
        )

        try ExamPersistenceService().save(result, in: container.mainContext)

        let statistics = try container.mainContext.fetch(FetchDescriptor<QuestionStatisticRecord>())
        let correctStat = try XCTUnwrap(statistics.first(where: { $0.questionID == "question-0" }))
        let incorrectStat = try XCTUnwrap(statistics.first(where: { $0.questionID == "question-1" }))
        XCTAssertEqual(correctStat.timesAnswered, 1)
        XCTAssertEqual(correctStat.correctCount, 1)
        XCTAssertEqual(correctStat.incorrectCount, 0)
        XCTAssertEqual(correctStat.lastAnsweredAt, date)
        XCTAssertEqual(incorrectStat.timesAnswered, 1)
        XCTAssertEqual(incorrectStat.correctCount, 0)
        XCTAssertEqual(incorrectStat.incorrectCount, 1)
        XCTAssertEqual(incorrectStat.lastAnsweredAt, date)

        let savedAnswers = try container.mainContext.fetch(FetchDescriptor<TestAnswerRecord>())
        XCTAssertEqual(savedAnswers.count, 2)
        XCTAssertTrue(savedAnswers.contains(where: { $0.questionID == "question-1" && !$0.isCorrect }))
        XCTAssertEqual(savedAnswers.first(where: { $0.questionID == "question-0" })?.answers, questions[0].answers)
    }

    @MainActor
    func testSameAttemptCannotBeSavedTwice() throws {
        let container = try makeInMemoryContainer()
        let questions = makeQuestions(count: 1)
        let result = try TestEvaluator().evaluate(questions: questions, selectedAnswers: ["question-0": "A"])
        let service = ExamPersistenceService()

        try service.save(result, in: container.mainContext)
        XCTAssertThrowsError(try service.save(result, in: container.mainContext))
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<StudyTestRecord>()).count, 1)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<QuestionStatisticRecord>()).first?.timesAnswered, 1)
    }

    @MainActor
    func testQuestionStatisticsAccumulateAcrossAttempts() throws {
        let container = try makeInMemoryContainer()
        let question = makeQuestions(count: 1)[0]
        let earlierDate = Date(timeIntervalSince1970: 1_700_000_000)
        let laterDate = Date(timeIntervalSince1970: 1_800_000_000)
        let evaluator = TestEvaluator()
        let service = ExamPersistenceService()
        let first = try evaluator.evaluate(questions: [question], selectedAnswers: [question.id: "A"], date: earlierDate)
        let second = try evaluator.evaluate(questions: [question], selectedAnswers: [question.id: "B"], date: laterDate)

        try service.save(first, in: container.mainContext)
        try service.save(second, in: container.mainContext)

        let statistic = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<QuestionStatisticRecord>()).first)
        XCTAssertEqual(statistic.timesAnswered, 2)
        XCTAssertEqual(statistic.correctCount, 1)
        XCTAssertEqual(statistic.incorrectCount, 1)
        XCTAssertEqual(statistic.lastAnsweredAt, laterDate)
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
                category: "DEMO - Seguridad",
                question: "Texto de la pregunta \(index)",
                answers: [
                    AnswerOption(id: "A", text: "Respuesta A"),
                    AnswerOption(id: "B", text: "Respuesta B"),
                    AnswerOption(id: "C", text: "Respuesta C")
                ],
                correctAnswer: "A",
                explanation: "Explicación guardada para \(index)",
                source: "Página demo \(index)",
                imageName: "demo-image-\(index)"
            )
        }
    }

    private func answers(for questions: [StudyQuestion], wrongCount: Int) -> [String: String] {
        Dictionary(uniqueKeysWithValues: questions.enumerated().map { index, question in
            (question.id, index < wrongCount ? "B" : "A")
        })
    }
}
