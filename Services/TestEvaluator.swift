import Foundation

enum TestEvaluationError: Error, LocalizedError {
    case emptyTest
    case duplicateQuestionID(String)
    case unansweredQuestion(String)
    case invalidSelectedAnswer(questionID: String, answerID: String)

    var errorDescription: String? {
        switch self {
        case .emptyTest:
            return "No se puede corregir un examen sin preguntas."
        case .duplicateQuestionID(let id):
            return "El examen contiene dos veces la pregunta \(id)."
        case .unansweredQuestion(let id):
            return "La pregunta \(id) no tiene una respuesta seleccionada."
        case .invalidSelectedAnswer(let questionID, let answerID):
            return "La opción \(answerID) no pertenece a la pregunta \(questionID)."
        }
    }
}

struct TestEvaluator {
    func evaluate(
        questions: [StudyQuestion],
        selectedAnswers: [String: String],
        attemptID: UUID = UUID(),
        date: Date = .now
    ) throws -> TestSessionSnapshot {
        guard !questions.isEmpty else { throw TestEvaluationError.emptyTest }

        var seenIDs = Set<String>()
        var answerSnapshots: [TestAnswerSnapshot] = []
        answerSnapshots.reserveCapacity(questions.count)

        for (position, question) in questions.enumerated() {
            guard seenIDs.insert(question.id).inserted else {
                throw TestEvaluationError.duplicateQuestionID(question.id)
            }
            guard let selectedAnswer = selectedAnswers[question.id] else {
                throw TestEvaluationError.unansweredQuestion(question.id)
            }
            guard question.answers.contains(where: { $0.id == selectedAnswer }) else {
                throw TestEvaluationError.invalidSelectedAnswer(questionID: question.id, answerID: selectedAnswer)
            }

            answerSnapshots.append(TestAnswerSnapshot(
                position: position,
                questionID: question.id,
                category: question.category,
                questionText: question.question,
                answers: question.answers,
                selectedAnswer: selectedAnswer,
                correctAnswer: question.correctAnswer,
                isCorrect: selectedAnswer == question.correctAnswer,
                explanation: question.explanation,
                source: question.source,
                imageName: question.imageName
            ))
        }

        let correctCount = answerSnapshots.filter(\.isCorrect).count
        return TestSessionSnapshot(
            id: attemptID,
            date: date,
            answers: answerSnapshots,
            correctCount: correctCount,
            incorrectCount: answerSnapshots.count - correctCount
        )
    }
}
