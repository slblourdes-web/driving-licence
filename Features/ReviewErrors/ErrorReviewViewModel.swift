import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class ErrorReviewViewModel {
    let questions: [StudyQuestion]

    private(set) var currentIndex = 0
    private(set) var selectedAnswer: String?
    private(set) var hasCheckedAnswer = false
    private(set) var checkedAnswerIsCorrect = false

    init(questions: [StudyQuestion]) {
        self.questions = questions
    }

    var questionCount: Int { questions.count }
    var isFinished: Bool { currentIndex >= questionCount }
    var currentQuestion: StudyQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    func selectAnswer(_ answerID: String) {
        guard !hasCheckedAnswer,
              let question = currentQuestion,
              question.answers.contains(where: { $0.id == answerID }) else { return }
        selectedAnswer = answerID
    }

    @discardableResult
    @MainActor
    func checkAnswer(in context: ModelContext) throws -> Bool {
        guard !hasCheckedAnswer,
              let question = currentQuestion,
              let selectedAnswer,
              question.answers.contains(where: { $0.id == selectedAnswer }) else { return false }

        let isCorrect = selectedAnswer == question.correctAnswer
        try ErrorReviewPersistenceService().recordAnswer(
            questionID: question.id,
            isCorrect: isCorrect,
            in: context
        )
        checkedAnswerIsCorrect = isCorrect
        hasCheckedAnswer = true
        return true
    }

    func advance() {
        guard hasCheckedAnswer else { return }
        currentIndex += 1
        selectedAnswer = nil
        hasCheckedAnswer = false
        checkedAnswerIsCorrect = false
    }
}
