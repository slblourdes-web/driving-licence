import Foundation

struct TestGenerator {
    func selectQuestions(from questions: [StudyQuestion], requestedCount: Int) -> [StudyQuestion] {
        guard requestedCount > 0 else { return [] }
        let uniqueQuestions = Array(Dictionary(questions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values)
        return Array(uniqueQuestions.shuffled().prefix(requestedCount))
    }
}
