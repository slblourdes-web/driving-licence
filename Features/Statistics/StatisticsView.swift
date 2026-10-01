import Charts
import SwiftData
import SwiftUI
import UIKit

struct StatisticsView: View {
    @Query(sort: \StudyTestRecord.date, order: .reverse) private var tests: [StudyTestRecord]
    @Query private var savedQuestionStatistics: [QuestionStatisticRecord]

    private var statistics: StudyStatistics {
        let questionStatistics = savedQuestionStatistics.map {
            QuestionStatistics(
                questionID: $0.questionID,
                timesAnswered: $0.timesAnswered,
                correctCount: $0.correctCount,
                incorrectCount: $0.incorrectCount
            )
        }
        return StatisticsCalculator().calculate(tests: tests.map(\.snapshot), questionStatistics: questionStatistics)
    }

    var body: some View {
        ScrollView {
            if statistics.overall.testCount == 0 {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    summarySection
                    performanceSection
                    evolutionSection
                    categoriesSection
                    difficultQuestionsSection
                }
                .padding(16)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Mis estadísticas")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Todavía no hay estadísticas.")
                .font(.headline)
            Text("Completa tu primer test para ver tus resultados y evolución.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var summarySection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("RESUMEN")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metric("Tests realizados", value: "\(statistics.overall.testCount)")
                    metric("Preguntas respondidas", value: "\(statistics.overall.questionCount)")
                    metric("Aciertos", value: "\(statistics.overall.correctCount)")
                    metric("Fallos", value: "\(statistics.overall.incorrectCount)")
                }
            }
        }
    }

    private var performanceSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("RENDIMIENTO")
                performanceRow("Aciertos globales", value: percent(statistics.overall.correctPercentage))
                performanceRow("Fallos globales", value: percent(statistics.overall.incorrectPercentage))
                Divider()
                periodSummary(title: "Últimos 5 tests", period: statistics.lastFive)
                Divider()
                periodSummary(title: "Últimos 10 tests", period: statistics.lastTen)
                Divider()
                performanceRow("Mejor resultado", value: percent(statistics.bestResultPercentage))
            }
        }
    }

    private var evolutionSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("EVOLUCIÓN")
                Text("Hasta los 20 tests más recientes, del más antiguo al más reciente.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Chart(statistics.evolution) { point in
                    LineMark(
                        x: .value("Test", point.sequence),
                        y: .value("Aciertos", point.correctPercentage)
                    )
                    .foregroundStyle(Color.accentColor)
                    PointMark(
                        x: .value("Test", point.sequence),
                        y: .value("Aciertos", point.correctPercentage)
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .chartYScale(domain: 0...100)
                .chartYAxisLabel("Aciertos (%)")
                .chartXAxisLabel("Tests recientes")
                .frame(height: 190)
                .accessibilityLabel("Evolución de aciertos de los tests más recientes")
            }
        }
    }

    private var categoriesSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("RENDIMIENTO POR TEMA")
                if statistics.categories.isEmpty {
                    Text("Todavía no hay categorías registradas.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(statistics.categories.indices, id: \.self) { index in
                        let category = statistics.categories[index]
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(category.category)
                                    .font(.headline)
                                Spacer(minLength: 4)
                                Text("Fallos: \(percent(category.incorrectPercentage))")
                                    .font(.subheadline.weight(.semibold))
                                    .multilineTextAlignment(.trailing)
                            }
                            Text("Respondidas: \(category.questionCount) · Aciertos: \(category.correctCount) · Errores: \(category.incorrectCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Aciertos: \(percent(category.correctPercentage))")
                                .font(.caption)
                        }
                        if index < statistics.categories.count - 1 { Divider() }
                    }
                }
            }
        }
    }

    private var difficultQuestionsSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("PREGUNTAS CON MÁS FALLOS")
                if statistics.mostMissedQuestions.isEmpty {
                    Text("Todavía no hay errores registrados.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(statistics.mostMissedQuestions.indices, id: \.self) { index in
                        let question = statistics.mostMissedQuestions[index]
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Pregunta \(question.questionID)")
                                .font(.headline)
                            if let text = question.questionText, !text.isEmpty {
                                Text(text)
                                    .lineLimit(2)
                                    .font(.subheadline)
                            }
                            Text("Respondida: \(question.timesAnswered) veces · Errores: \(question.incorrectCount) · Error: \(percent(question.errorPercentage))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if index < statistics.mostMissedQuestions.count - 1 { Divider() }
                    }
                }
            }
        }
    }

    private func periodSummary(title: String, period: StatisticsPeriod) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            if period.testCount == 0 {
                Text("Todavía no hay tests.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                performanceRow("Aciertos", value: percent(period.correctPercentage))
                performanceRow("Fallos", value: percent(period.incorrectPercentage))
                Text("Calculado con \(period.testCount) tests y \(period.questionCount) preguntas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func performanceRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
            Spacer(minLength: 8)
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .accessibilityAddTraits(.isHeader)
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title3.weight(.bold))
                .contentTransition(.numericText())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }
}
