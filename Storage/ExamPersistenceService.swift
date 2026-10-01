import Foundation
import SwiftData

enum ExamPersistenceError: Error, LocalizedError {
    case duplicateAttempt(UUID)

    var errorDescription: String? {
        switch self {
        case .duplicateAttempt(let id): return "El examen \(id.uuidString) ya se guardó."
        }
    }
}

@MainActor
struct ExamPersistenceService {
    func save(_ result: TestSessionSnapshot, in context: ModelContext) throws {
        let attemptID = result.id
        let duplicateRequest = FetchDescriptor<StudyTestRecord>(predicate: #Predicate { $0.id == attemptID })
        guard try context.fetch(duplicateRequest).isEmpty else {
            throw ExamPersistenceError.duplicateAttempt(attemptID)
        }

        do {
            let answerRecords = try result.answers.map(TestAnswerRecord.init(snapshot:))
            let testRecord = StudyTestRecord(
                id: result.id,
                date: result.date,
                correctCount: result.correctCount,
                incorrectCount: result.incorrectCount,
                answers: answerRecords
            )
            context.insert(testRecord)

            for (snapshot, answerRecord) in zip(result.answers, answerRecords) {
                context.insert(answerRecord)
                let questionID = snapshot.questionID
                let statisticRequest = FetchDescriptor<QuestionStatisticRecord>(
                    predicate: #Predicate { $0.questionID == questionID }
                )
                if let statistic = try context.fetch(statisticRequest).first {
                    statistic.timesAnswered += 1
                    if snapshot.isCorrect {
                        statistic.correctCount += 1
                    } else {
                        statistic.incorrectCount += 1
                    }
                    statistic.lastAnsweredAt = result.date
                } else {
                    context.insert(QuestionStatisticRecord(
                        questionID: questionID,
                        timesAnswered: 1,
                        correctCount: snapshot.isCorrect ? 1 : 0,
                        incorrectCount: snapshot.isCorrect ? 0 : 1,
                        lastAnsweredAt: result.date
                    ))
                }
            }

            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
