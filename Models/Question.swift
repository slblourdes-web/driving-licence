import Foundation

struct AnswerOption: Codable, Identifiable, Hashable {
    let id: String
    let text: String
}

struct QuestionCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
}

struct StudyQuestion: Codable, Identifiable, Hashable {
    let id: String
    let category: String
    let question: String
    let answers: [AnswerOption]
    let correctAnswer: String
    let explanation: String
    let source: String?
    let imageName: String?
}
