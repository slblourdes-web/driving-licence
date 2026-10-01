import Foundation

struct QuestionStatistics: Codable, Identifiable, Hashable {
    let questionID: String
    var timesAnswered: Int
    var correctCount: Int
    var incorrectCount: Int

    var id: String { questionID }
    var errorPercentage: Double {
        guard timesAnswered > 0 else { return 0 }
        return Double(incorrectCount) / Double(timesAnswered) * 100
    }
}
