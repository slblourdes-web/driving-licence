import Foundation
import XCTest
@testable import DrivingStudy

final class StatisticsCalculatorTests: XCTestCase {
    func testZeroTestsReturnsAnEmptySummaryWithoutDivisionByZero() {
        let statistics = StatisticsCalculator().calculate(tests: [], questionStatistics: [questionStat(id: "unused", answered: 0, errors: 0)])

        XCTAssertEqual(statistics.overall.testCount, 0)
        XCTAssertEqual(statistics.overall.questionCount, 0)
        XCTAssertEqual(statistics.overall.correctPercentage, 0)
        XCTAssertEqual(statistics.overall.incorrectPercentage, 0)
        XCTAssertEqual(statistics.bestResultPercentage, 0)
        XCTAssertTrue(statistics.evolution.isEmpty)
        XCTAssertTrue(statistics.categories.isEmpty)
        XCTAssertTrue(statistics.mostMissedQuestions.isEmpty)
        XCTAssertEqual(QuestionStatistics(questionID: "none", timesAnswered: 0, correctCount: 0, incorrectCount: 0).errorPercentage, 0)
    }

    func testOneTestAndFewerThanFiveUseAllAvailableTests() {
        let one = makeTest(day: 1, total: 10, correct: 7)
        let oneSummary = StatisticsCalculator().calculate(tests: [one], questionStatistics: [])
        XCTAssertEqual(oneSummary.overall.testCount, 1)
        XCTAssertEqual(oneSummary.lastFive.testCount, 1)
        XCTAssertEqual(oneSummary.lastTen.testCount, 1)
        XCTAssertEqual(oneSummary.bestResultPercentage, 70, accuracy: 0.0001)

        let three = (1...3).map { makeTest(day: $0, total: 10, correct: $0 * 2) }
        let threeSummary = StatisticsCalculator().calculate(tests: three, questionStatistics: [])
        XCTAssertEqual(threeSummary.lastFive.testCount, 3)
        XCTAssertEqual(threeSummary.lastTen.testCount, 3)
    }

    func testExactlyFiveAndMoreThanFiveTestsUseAtMostFiveMostRecent() {
        let exactlyFive = (1...5).map { makeTest(day: $0, total: 10, correct: $0) }
        let exactSummary = StatisticsCalculator().calculate(tests: exactlyFive, questionStatistics: [])
        XCTAssertEqual(exactSummary.lastFive.testCount, 5)
        XCTAssertEqual(exactSummary.lastFive.questionCount, 50)

        let six = (1...6).map { makeTest(day: $0, total: 10, correct: $0) }
        let sixSummary = StatisticsCalculator().calculate(tests: six, questionStatistics: [])
        XCTAssertEqual(sixSummary.lastFive.testCount, 5)
        XCTAssertEqual(sixSummary.lastFive.questionCount, 50)
        XCTAssertEqual(sixSummary.lastFive.correctCount, 20)
    }

    func testExactlyTenAndMoreThanTenTestsUseAtMostTenMostRecent() {
        let exactlyTen = (1...10).map { makeTest(day: $0, total: 10, correct: $0) }
        let exactSummary = StatisticsCalculator().calculate(tests: exactlyTen, questionStatistics: [])
        XCTAssertEqual(exactSummary.lastTen.testCount, 10)

        let eleven = (1...11).map { makeTest(day: $0, total: 10, correct: $0) }
        let elevenSummary = StatisticsCalculator().calculate(tests: eleven, questionStatistics: [])
        XCTAssertEqual(elevenSummary.lastTen.testCount, 10)
        XCTAssertEqual(elevenSummary.lastTen.questionCount, 100)
        XCTAssertEqual(elevenSummary.lastTen.correctCount, 65)
    }

    func testGlobalPercentageUsesQuestionTotalsRatherThanMeanOfTestPercentages() {
        let tests = [makeTest(day: 1, total: 2, correct: 1), makeTest(day: 2, total: 10, correct: 9)]
        let summary = StatisticsCalculator().calculate(tests: tests, questionStatistics: [])

        XCTAssertEqual(summary.overall.correctCount, 10)
        XCTAssertEqual(summary.overall.questionCount, 12)
        XCTAssertEqual(summary.overall.correctPercentage, 10.0 / 12.0 * 100.0, accuracy: 0.0001)
        XCTAssertGreaterThan(abs(summary.overall.correctPercentage - 70), 1)
    }

    func testRecentFiveAndTenPercentagesAreWeightedByQuestionCount() {
        let tests = [
            makeTest(day: 1, total: 10, correct: 10),
            makeTest(day: 2, total: 2, correct: 0),
            makeTest(day: 3, total: 10, correct: 10),
            makeTest(day: 4, total: 10, correct: 0),
            makeTest(day: 5, total: 1, correct: 1),
            makeTest(day: 6, total: 9, correct: 0),
            makeTest(day: 7, total: 3, correct: 3)
        ]
        let summary = StatisticsCalculator().calculate(tests: tests, questionStatistics: [])

        XCTAssertEqual(summary.lastFive.testCount, 5)
        XCTAssertEqual(summary.lastFive.questionCount, 33)
        XCTAssertEqual(summary.lastFive.correctCount, 14)
        XCTAssertEqual(summary.lastFive.correctPercentage, 14.0 / 33.0 * 100, accuracy: 0.0001)
        XCTAssertEqual(summary.lastFive.incorrectPercentage, 19.0 / 33.0 * 100, accuracy: 0.0001)
        XCTAssertEqual(summary.lastTen.testCount, 7)
        XCTAssertEqual(summary.lastTen.questionCount, 45)
        XCTAssertEqual(summary.lastTen.correctCount, 24)
        XCTAssertEqual(summary.lastTen.correctPercentage, 24.0 / 45.0 * 100, accuracy: 0.0001)
    }

    func testBestResultAndEvolutionAreChronological() {
        let chronological = (1...4).map { makeTest(day: $0, total: 10, correct: $0 * 2) }
        let statistics = StatisticsCalculator().calculate(tests: Array(chronological.reversed()), questionStatistics: [])

        XCTAssertEqual(statistics.bestResultPercentage, 80, accuracy: 0.0001)
        XCTAssertEqual(statistics.evolution.map(\.date), chronological.map(\.date))
        XCTAssertEqual(statistics.evolution.map(\.correctPercentage), [20, 40, 60, 80])
        XCTAssertEqual(statistics.evolution.map(\.sequence), [1, 2, 3, 4])
    }

    func testEvolutionIsLimitedToTwentyMostRecentTests() {
        let tests = (1...25).map { makeTest(day: $0, total: 100, correct: $0) }
        let evolution = StatisticsCalculator().calculate(tests: tests, questionStatistics: []).evolution

        XCTAssertEqual(evolution.count, 20)
        XCTAssertEqual(evolution.first?.date, tests[5].date)
        XCTAssertEqual(evolution.last?.date, tests[24].date)
        XCTAssertEqual(evolution.map(\.sequence), Array(1...20))
    }

    func testCategoriesAggregateCorrectAndIncorrectAnswers() {
        let test = makeTest(day: 1, total: 4, correct: 3)
        let categories = StatisticsCalculator().calculate(tests: [test], questionStatistics: []).categories
        let priority = categories.first(where: { $0.category == "Prioridad" })
        let signs = categories.first(where: { $0.category == "Señales" })

        XCTAssertEqual(priority?.questionCount, 2)
        XCTAssertEqual(priority?.correctCount, 2)
        XCTAssertEqual(priority?.incorrectCount, 0)
        XCTAssertEqual(priority?.correctPercentage, 100)
        XCTAssertEqual(priority?.incorrectPercentage, 0)
        XCTAssertEqual(signs?.questionCount, 2)
        XCTAssertEqual(signs?.correctCount, 1)
        XCTAssertEqual(signs?.incorrectCount, 1)
        XCTAssertEqual(signs?.correctPercentage, 50)
        XCTAssertEqual(signs?.incorrectPercentage, 50)
    }

    func testMostMissedQuestionsAreOrderedByErrorsAndShowDenominator() {
        let tests = [makeTest(day: 1, total: 3, correct: 1)]
        let stored = [
            questionStat(id: "question-1-0", answered: 8, errors: 5),
            questionStat(id: "question-1-1", answered: 4, errors: 4),
            questionStat(id: "question-1-2", answered: 0, errors: 0)
        ]
        let hardest = StatisticsCalculator().calculate(tests: tests, questionStatistics: stored).mostMissedQuestions

        XCTAssertEqual(hardest.map(\.questionID), ["question-1-0", "question-1-1"])
        XCTAssertEqual(hardest[0].timesAnswered, 8)
        XCTAssertEqual(hardest[0].incorrectCount, 5)
        XCTAssertEqual(hardest[0].errorPercentage, 62.5, accuracy: 0.0001)
        XCTAssertEqual(hardest[0].questionText, "Texto question-1-0")
    }

    func testMostMissedQuestionsAreLimitedToTen() {
        let test = makeTest(day: 1, total: 10, correct: 10)
        let stored = (0..<12).map { questionStat(id: "hard-\($0)", answered: 10, errors: $0) }
        let hardest = StatisticsCalculator().calculate(tests: [test], questionStatistics: stored).mostMissedQuestions

        XCTAssertEqual(hardest.count, 10)
        XCTAssertEqual(hardest.first?.questionID, "hard-11")
        XCTAssertEqual(hardest.last?.questionID, "hard-2")
    }

    private func makeTest(day: Int, total: Int, correct: Int) -> TestSessionSnapshot {
        let answers = (0..<total).map { position in
            let isCorrect = position < correct
            let category = position.isMultiple(of: 2) ? "Prioridad" : "Señales"
            return TestAnswerSnapshot(
                position: position,
                questionID: "question-\(day)-\(position)",
                category: category,
                questionText: "Texto question-\(day)-\(position)",
                answers: [
                    AnswerOption(id: "A", text: "Opción A"),
                    AnswerOption(id: "B", text: "Opción B"),
                    AnswerOption(id: "C", text: "Opción C")
                ],
                selectedAnswer: isCorrect ? "A" : "B",
                correctAnswer: "A",
                isCorrect: isCorrect,
                explanation: "Explicación",
                source: nil,
                imageName: nil
            )
        }
        return TestSessionSnapshot(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", day))!,
            date: Date(timeIntervalSince1970: TimeInterval(day * 86_400)),
            answers: answers,
            correctCount: correct,
            incorrectCount: total - correct
        )
    }

    private func questionStat(id: String, answered: Int, errors: Int) -> QuestionStatistics {
        QuestionStatistics(questionID: id, timesAnswered: answered, correctCount: answered - errors, incorrectCount: errors)
    }
}
