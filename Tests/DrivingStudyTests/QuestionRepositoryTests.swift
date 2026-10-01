import XCTest
@testable import DrivingStudy

final class QuestionRepositoryTests: XCTestCase {
    func testDemoBankLoadsAndHasUniqueIDs() throws {
        let questions = try QuestionRepository().loadQuestions(bundle: Bundle(for: Self.self))
        XCTAssertEqual(questions.count, 10)
        XCTAssertEqual(Set(questions.map(\.id)).count, 10)
        XCTAssertTrue(questions.allSatisfy { $0.id.hasPrefix("demo-") })
    }

    func testGeneratorReturnsUniqueAvailableQuestions() throws {
        let questions = try QuestionRepository().loadQuestions(bundle: Bundle(for: Self.self))
        let selected = TestGenerator().selectQuestions(from: questions, requestedCount: 25)
        XCTAssertEqual(selected.count, 10)
        XCTAssertEqual(Set(selected.map(\.id)).count, selected.count)
    }

    func testGeneratorReturnsRequestedCountWhenEnoughQuestionsExist() throws {
        let questions = try QuestionRepository().loadQuestions(bundle: Bundle(for: Self.self))
        let expanded = (0..<3).flatMap { copy in
            questions.map { question in
                StudyQuestion(id: "\(question.id)-\(copy)", category: question.category, question: question.question, answers: question.answers, correctAnswer: question.correctAnswer, explanation: question.explanation, source: question.source, imageName: question.imageName)
            }
        }
        let selected = TestGenerator().selectQuestions(from: expanded, requestedCount: 25)
        XCTAssertEqual(selected.count, 25)
        XCTAssertEqual(Set(selected.map(\.id)).count, 25)
    }
}
