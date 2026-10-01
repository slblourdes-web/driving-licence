import Foundation

struct StatisticsPeriod: Hashable {
    let testCount: Int
    let questionCount: Int
    let correctCount: Int
    let incorrectCount: Int

    var correctPercentage: Double { Self.percentage(correctCount, total: questionCount) }
    var incorrectPercentage: Double { Self.percentage(incorrectCount, total: questionCount) }

    static func percentage(_ count: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total) * 100
    }
}

struct ScoreEvolutionPoint: Identifiable, Hashable {
    let id: UUID
    let sequence: Int
    let date: Date
    let correctPercentage: Double
}

struct CategoryStatistics: Identifiable, Hashable {
    let category: String
    let questionCount: Int
    let correctCount: Int
    let incorrectCount: Int

    var id: String { category }
    var correctPercentage: Double { StatisticsPeriod.percentage(correctCount, total: questionCount) }
    var incorrectPercentage: Double { StatisticsPeriod.percentage(incorrectCount, total: questionCount) }
}

struct DifficultQuestionStatistics: Identifiable, Hashable {
    let questionID: String
    let questionText: String?
    let timesAnswered: Int
    let incorrectCount: Int
    let errorPercentage: Double

    var id: String { questionID }
}

struct StudyStatistics: Hashable {
    let overall: StatisticsPeriod
    let bestResultPercentage: Double
    let lastFive: StatisticsPeriod
    let lastTen: StatisticsPeriod
    let evolution: [ScoreEvolutionPoint]
    let categories: [CategoryStatistics]
    let mostMissedQuestions: [DifficultQuestionStatistics]

    static let empty = StudyStatistics(
        overall: StatisticsPeriod(testCount: 0, questionCount: 0, correctCount: 0, incorrectCount: 0),
        bestResultPercentage: 0,
        lastFive: StatisticsPeriod(testCount: 0, questionCount: 0, correctCount: 0, incorrectCount: 0),
        lastTen: StatisticsPeriod(testCount: 0, questionCount: 0, correctCount: 0, incorrectCount: 0),
        evolution: [],
        categories: [],
        mostMissedQuestions: []
    )
}

struct StatisticsCalculator {
    let evolutionLimit: Int
    let difficultQuestionLimit: Int

    init(evolutionLimit: Int = 20, difficultQuestionLimit: Int = 10) {
        self.evolutionLimit = max(0, evolutionLimit)
        self.difficultQuestionLimit = max(0, difficultQuestionLimit)
    }

    func calculate(tests: [TestSessionSnapshot], questionStatistics: [QuestionStatistics]) -> StudyStatistics {
        guard !tests.isEmpty else { return .empty }

        let newestFirst = tests.sorted(by: newestFirstOrder)
        let chronological = Array(newestFirst.reversed())
        let allAnswers = chronological.flatMap(\.answers)
        let questionTextByID = Dictionary(allAnswers.map { ($0.questionID, $0.questionText) }, uniquingKeysWith: { _, newest in newest })
        let bestResult = tests.map(\.correctPercentage).max() ?? 0

        let evolutionTests = Array(chronological.suffix(evolutionLimit))
        let evolution = evolutionTests.enumerated().map { index, test in
            ScoreEvolutionPoint(id: test.id, sequence: index + 1, date: test.date, correctPercentage: test.correctPercentage)
        }

        let categories = Dictionary(grouping: allAnswers, by: \.category)
            .map { category, answers in
                let correct = answers.filter(\.isCorrect).count
                return CategoryStatistics(
                    category: category,
                    questionCount: answers.count,
                    correctCount: correct,
                    incorrectCount: answers.count - correct
                )
            }
            .sorted { $0.category.localizedStandardCompare($1.category) == .orderedAscending }

        let hardest = questionStatistics
            .filter { $0.timesAnswered > 0 }
            .map { statistic in
                DifficultQuestionStatistics(
                    questionID: statistic.questionID,
                    questionText: questionTextByID[statistic.questionID],
                    timesAnswered: statistic.timesAnswered,
                    incorrectCount: statistic.incorrectCount,
                    errorPercentage: statistic.errorPercentage
                )
            }
            .sorted {
                if $0.incorrectCount != $1.incorrectCount { return $0.incorrectCount > $1.incorrectCount }
                if $0.errorPercentage != $1.errorPercentage { return $0.errorPercentage > $1.errorPercentage }
                if $0.timesAnswered != $1.timesAnswered { return $0.timesAnswered > $1.timesAnswered }
                return $0.questionID < $1.questionID
            }

        return StudyStatistics(
            overall: summarize(tests),
            bestResultPercentage: bestResult,
            lastFive: summarize(Array(newestFirst.prefix(5))),
            lastTen: summarize(Array(newestFirst.prefix(10))),
            evolution: evolution,
            categories: categories,
            mostMissedQuestions: Array(hardest.prefix(difficultQuestionLimit))
        )
    }

    private func summarize(_ tests: [TestSessionSnapshot]) -> StatisticsPeriod {
        StatisticsPeriod(
            testCount: tests.count,
            questionCount: tests.reduce(0) { $0 + $1.questionCount },
            correctCount: tests.reduce(0) { $0 + $1.correctCount },
            incorrectCount: tests.reduce(0) { $0 + $1.incorrectCount }
        )
    }

    private func newestFirstOrder(_ lhs: TestSessionSnapshot, _ rhs: TestSessionSnapshot) -> Bool {
        if lhs.date != rhs.date { return lhs.date > rhs.date }
        return lhs.id.uuidString > rhs.id.uuidString
    }
}
