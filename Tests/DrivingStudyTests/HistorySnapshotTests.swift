import XCTest
import SwiftData
@testable import DrivingStudy

final class HistorySnapshotTests: XCTestCase {
    @MainActor
    func testHistoricalTestCanBeRebuiltOnlyFromPersistedSnapshots() throws {
        let container = try ModelContainer(
            for: StudyTestRecord.self,
            TestAnswerRecord.self,
            QuestionStatisticRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let originalAnswer = TestAnswerSnapshot(
            position: 0,
            questionID: "demo-004",
            category: "DEMO - Seguridad",
            questionText: "Texto histórico capturado al realizar el test",
            answers: [
                AnswerOption(id: "A", text: "Opción histórica A"),
                AnswerOption(id: "B", text: "Opción histórica B"),
                AnswerOption(id: "C", text: "Opción histórica C")
            ],
            selectedAnswer: "B",
            correctAnswer: "A",
            isCorrect: false,
            explanation: "Explicación histórica original",
            source: "Temario, sección de demostración",
            imageName: "demo-road-image"
        )
        let secondAnswer = TestAnswerSnapshot(
            position: 1,
            questionID: "demo-001",
            category: "DEMO - Prioridad",
            questionText: "Segunda pregunta histórica",
            answers: [
                AnswerOption(id: "A", text: "Sí"),
                AnswerOption(id: "B", text: "No"),
                AnswerOption(id: "C", text: "Quizá")
            ],
            selectedAnswer: "A",
            correctAnswer: "A",
            isCorrect: true,
            explanation: "Segunda explicación guardada",
            source: nil,
            imageName: nil
        )
        let session = TestSessionSnapshot(
            id: UUID(),
            date: Date(timeIntervalSince1970: 1_800_000_000),
            answers: [secondAnswer, originalAnswer],
            correctCount: 1,
            incorrectCount: 1
        )

        try ExamPersistenceService().save(session, in: container.mainContext)
        let persisted = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<StudyTestRecord>()).first)
        let rebuilt = persisted.snapshot
        let answer = try XCTUnwrap(rebuilt.answers.first)

        XCTAssertEqual(rebuilt.id, session.id)
        XCTAssertEqual(rebuilt.date, session.date)
        XCTAssertEqual(rebuilt.correctCount, 1)
        XCTAssertEqual(rebuilt.incorrectCount, 1)
        XCTAssertEqual(rebuilt.answers.map(\.questionID), ["demo-004", "demo-001"])
        XCTAssertEqual(answer.position, 0)
        XCTAssertEqual(answer.questionID, "demo-004")
        XCTAssertEqual(answer.category, originalAnswer.category)
        XCTAssertEqual(answer.questionText, originalAnswer.questionText)
        XCTAssertEqual(answer.answers, originalAnswer.answers)
        XCTAssertEqual(answer.selectedAnswer, "B")
        XCTAssertEqual(answer.correctAnswer, "A")
        XCTAssertFalse(answer.isCorrect)
        XCTAssertEqual(answer.explanation, originalAnswer.explanation)
        XCTAssertEqual(answer.source, originalAnswer.source)
        XCTAssertEqual(answer.imageName, originalAnswer.imageName)
    }
}
