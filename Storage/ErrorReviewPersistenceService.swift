import Foundation
import SwiftData

enum ErrorReviewPersistenceError: Error, LocalizedError {
    case questionStatisticsNotFound(String)

    var errorDescription: String? {
        switch self {
        case .questionStatisticsNotFound(let id):
            return "No se encontraron estadísticas para la pregunta \(id)."
        }
    }
}

@MainActor
struct ErrorReviewPersistenceService {
    func recordAnswer(questionID: String, isCorrect: Bool, at date: Date = .now, in context: ModelContext) throws {
        let statisticRequest = FetchDescriptor<QuestionStatisticRecord>(
            predicate: #Predicate { $0.questionID == questionID }
        )
        guard let statistic = try context.fetch(statisticRequest).first else {
            throw ErrorReviewPersistenceError.questionStatisticsNotFound(questionID)
        }

        statistic.timesAnswered += 1
        if isCorrect {
            statistic.correctCount += 1
        } else {
            statistic.incorrectCount += 1
        }
        statistic.lastAnsweredAt = date

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
