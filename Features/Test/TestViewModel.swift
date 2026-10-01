import Combine
import Foundation
import SwiftData

final class TestViewModel: ObservableObject {
    let questions: [StudyQuestion]

    @Published private(set) var currentIndex = 0
    @Published private(set) var selectedAnswers: [String: String] = [:]
    @Published private(set) var isCompleted = false
    @Published private(set) var evaluatedResult: TestSessionSnapshot?
    private let attemptID = UUID()

    init(questions: [StudyQuestion]) {
        precondition(!questions.isEmpty, "Un test necesita al menos una pregunta.")
        precondition(Set(questions.map(\.id)).count == questions.count, "Un test no puede contener preguntas repetidas.")
        self.questions = questions
    }

    var currentQuestion: StudyQuestion { questions[currentIndex] }
    var questionCount: Int { questions.count }
    var answeredCount: Int { selectedAnswers.count }
    var unansweredCount: Int { questionCount - answeredCount }
    var progress: Double { Double(currentIndex + 1) / Double(questionCount) }
    var canFinish: Bool { unansweredCount == 0 && !isCompleted }

    func selectedAnswer(for question: StudyQuestion) -> String? {
        selectedAnswers[question.id]
    }

    func selectAnswer(_ answerID: String) {
        guard !isCompleted, currentQuestion.answers.contains(where: { $0.id == answerID }) else { return }
        selectedAnswers[currentQuestion.id] = answerID
    }

    func goToPreviousQuestion() {
        guard currentIndex > 0, !isCompleted else { return }
        currentIndex -= 1
    }

    func goToNextQuestion() {
        guard currentIndex < questionCount - 1, !isCompleted else { return }
        currentIndex += 1
    }

    func goToFirstUnansweredQuestion() {
        guard let pendingIndex = questions.firstIndex(where: { selectedAnswers[$0.id] == nil }) else { return }
        currentIndex = pendingIndex
    }

    @discardableResult
    @MainActor
    func finish(using context: ModelContext) throws -> Bool {
        guard canFinish else { return false }
        let result = try TestEvaluator().evaluate(
            questions: questions,
            selectedAnswers: selectedAnswers,
            attemptID: attemptID
        )
        try ExamPersistenceService().save(result, in: context)
        evaluatedResult = result
        isCompleted = true
        return true
    }
}
