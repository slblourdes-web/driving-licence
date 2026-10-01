import XCTest
import SwiftData
@testable import DrivingStudy

final class TestViewModelTests: XCTestCase {
    func testStartingWithTenAvailableQuestionsCreatesTenUniqueQuestions() throws {
        let bank = try QuestionRepository().loadQuestions(bundle: Bundle(for: Self.self))
        let selected = TestGenerator().selectQuestions(from: bank, requestedCount: 25)
        let viewModel = TestViewModel(questions: selected)

        XCTAssertEqual(viewModel.questionCount, 10)
        XCTAssertEqual(Set(viewModel.questions.map(\.id)).count, 10)
    }

    func testSelectingAndChangingAnswerStoresLatestChoice() {
        let viewModel = TestViewModel(questions: makeQuestions(count: 2))

        viewModel.selectAnswer("A")
        XCTAssertEqual(viewModel.selectedAnswer(for: viewModel.currentQuestion), "A")
        viewModel.selectAnswer("B")

        XCTAssertEqual(viewModel.selectedAnswer(for: viewModel.currentQuestion), "B")
        XCTAssertEqual(viewModel.answeredCount, 1)
    }

    func testNavigationKeepsAnswersForEachQuestion() {
        let viewModel = TestViewModel(questions: makeQuestions(count: 3))
        viewModel.selectAnswer("C")
        viewModel.goToNextQuestion()
        viewModel.selectAnswer("B")
        viewModel.goToPreviousQuestion()

        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.selectedAnswer(for: viewModel.currentQuestion), "C")
        viewModel.goToNextQuestion()
        XCTAssertEqual(viewModel.selectedAnswer(for: viewModel.currentQuestion), "B")
    }

    func testPendingQuestionsAreDetectedAndCanBeOpened() {
        let viewModel = TestViewModel(questions: makeQuestions(count: 3))
        viewModel.selectAnswer("A")

        XCTAssertEqual(viewModel.unansweredCount, 2)
        XCTAssertFalse(viewModel.canFinish)
        viewModel.goToFirstUnansweredQuestion()
        XCTAssertEqual(viewModel.currentIndex, 1)
    }

    func testAllAnsweredQuestionsAllowCompletion() {
        let viewModel = TestViewModel(questions: makeQuestions(count: 3))
        for index in viewModel.questions.indices {
            viewModel.selectAnswer("A")
            if index < viewModel.questions.count - 1 { viewModel.goToNextQuestion() }
        }

        XCTAssertEqual(viewModel.unansweredCount, 0)
        XCTAssertTrue(viewModel.canFinish)
    }

    func testCannotCompleteWhileAnyQuestionIsUnanswered() {
        let viewModel = TestViewModel(questions: makeQuestions(count: 2))
        viewModel.selectAnswer("A")

        XCTAssertFalse(viewModel.canFinish)
        XCTAssertFalse(viewModel.isCompleted)
    }

    @MainActor
    func testSuccessfulFinishSavesOnceAndThenLocksTheSession() throws {
        let questions = makeQuestions(count: 2)
        let viewModel = TestViewModel(questions: questions)
        viewModel.selectAnswer("A")
        viewModel.goToNextQuestion()
        viewModel.selectAnswer("B")
        let container = try ModelContainer(
            for: StudyTestRecord.self,
            TestAnswerRecord.self,
            QuestionStatisticRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        XCTAssertTrue(try viewModel.finish(using: container.mainContext))
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertEqual(viewModel.evaluatedResult?.questionCount, 2)
        XCTAssertFalse(try viewModel.finish(using: container.mainContext))
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<StudyTestRecord>()).count, 1)
    }

    private func makeQuestions(count: Int) -> [StudyQuestion] {
        (0..<count).map { index in
            StudyQuestion(
                id: "test-\(index)",
                category: "DEMO - Test",
                question: "Pregunta de prueba \(index)",
                answers: [
                    AnswerOption(id: "A", text: "Opción A"),
                    AnswerOption(id: "B", text: "Opción B"),
                    AnswerOption(id: "C", text: "Opción C")
                ],
                correctAnswer: "A",
                explanation: "Explicación de prueba",
                source: nil,
                imageName: nil
            )
        }
    }
}
