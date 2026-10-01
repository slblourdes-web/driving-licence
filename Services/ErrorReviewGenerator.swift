import Foundation

struct ErrorReviewGenerator {
    /// Keeps every question with a previous mistake. More frequent mistakes come first.
    func selectQuestions(
        from questions: [StudyQuestion],
        statistics: [QuestionStatistics]
    ) -> [StudyQuestion] {
        let questionsByID = Dictionary(questions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return statistics
            .filter { $0.incorrectCount > 0 }
            .sorted {
                if $0.incorrectCount != $1.incorrectCount { return $0.incorrectCount > $1.incorrectCount }
                if $0.errorPercentage != $1.errorPercentage { return $0.errorPercentage > $1.errorPercentage }
                if $0.timesAnswered != $1.timesAnswered { return $0.timesAnswered > $1.timesAnswered }
                return $0.questionID < $1.questionID
            }
            .compactMap { questionsByID[$0.questionID] }
    }
}
