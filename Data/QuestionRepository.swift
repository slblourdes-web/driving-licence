import Foundation

enum QuestionRepositoryError: Error, LocalizedError {
    case resourceNotFound(String)
    case invalidJSON(String)
    case duplicateID(String)
    case invalidQuestion(id: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name): return "No se encontró el recurso \(name).json en el bundle."
        case .invalidJSON(let detail): return "Questions.json no tiene un formato válido: \(detail)"
        case .duplicateID(let id): return "ID de pregunta duplicado: \(id)"
        case .invalidQuestion(let id, let reason): return "Pregunta \(id): \(reason)"
        }
    }
}

struct QuestionRepository {
    func loadQuestions(bundle: Bundle = .main, resourceName: String = "Questions") throws -> [StudyQuestion] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw QuestionRepositoryError.resourceNotFound(resourceName)
        }

        let data = try Data(contentsOf: url)
        let questions: [StudyQuestion]
        do {
            questions = try JSONDecoder().decode([StudyQuestion].self, from: data)
        } catch {
            throw QuestionRepositoryError.invalidJSON(error.localizedDescription)
        }
        try validate(questions)
        return questions
    }

    func validate(_ questions: [StudyQuestion]) throws {
        var seenIDs = Set<String>()
        for question in questions {
            guard !question.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw QuestionRepositoryError.invalidQuestion(id: "<vacío>", reason: "el ID es obligatorio")
            }
            guard seenIDs.insert(question.id).inserted else {
                throw QuestionRepositoryError.duplicateID(question.id)
            }
            for (field, value) in [("category", question.category), ("question", question.question), ("explanation", question.explanation)] {
                guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw QuestionRepositoryError.invalidQuestion(id: question.id, reason: "el campo obligatorio \(field) está vacío")
                }
            }
            guard question.answers.count == 3 else {
                throw QuestionRepositoryError.invalidQuestion(id: question.id, reason: "debe tener exactamente 3 respuestas")
            }
            let answerIDs = question.answers.map(\.id)
            guard Set(answerIDs).count == 3, answerIDs.allSatisfy({ ["A", "B", "C"].contains($0) }) else {
                throw QuestionRepositoryError.invalidQuestion(id: question.id, reason: "las respuestas deben tener IDs únicos A, B y C")
            }
            guard question.answers.allSatisfy({ !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                throw QuestionRepositoryError.invalidQuestion(id: question.id, reason: "el texto de cada respuesta es obligatorio")
            }
            guard answerIDs.contains(question.correctAnswer) else {
                throw QuestionRepositoryError.invalidQuestion(id: question.id, reason: "correctAnswer debe ser A, B o C y existir entre las respuestas")
            }
        }
    }
}
