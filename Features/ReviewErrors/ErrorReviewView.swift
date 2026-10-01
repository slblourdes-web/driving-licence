import SwiftData
import SwiftUI
import UIKit

struct ErrorReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var questionStatistics: [QuestionStatisticRecord]

    @State private var viewModel: ErrorReviewViewModel?
    @State private var loadError: String?
    @State private var actionError: String?

    var body: some View {
        Group {
            if let loadError {
                messageState(title: "No se pudieron cargar las preguntas", message: loadError, symbol: "exclamationmark.triangle")
            } else if let viewModel {
                if viewModel.questionCount == 0 {
                    messageState(title: "Todavía no hay errores para repasar", message: "Cuando falles una pregunta en un test, aparecerá aquí.", symbol: "checkmark.circle")
                } else if viewModel.isFinished {
                    finishedState
                } else if let question = viewModel.currentQuestion {
                    practiceContent(viewModel: viewModel, question: question)
                }
            } else {
                ProgressView("Preparando el repaso…")
            }
        }
        .navigationTitle("Repasar errores")
        .navigationBarTitleDisplayMode(.inline)
        .task { loadQuestionsIfNeeded() }
        .alert("No se pudo guardar la respuesta", isPresented: Binding(
            get: { actionError != nil },
            set: { if !$0 { actionError = nil } }
        )) {
            Button("Intentar de nuevo", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
    }

    private var finishedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text("Repaso completado")
                .font(.title2.bold())
            Text("Las preguntas que ya habías fallado seguirán apareciendo aquí para que puedas volver a practicarlas.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("VOLVER AL INICIO") { dismiss() }
                .buttonStyle(.borderedProminent)
                .frame(minHeight: 48)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func practiceContent(viewModel: ErrorReviewViewModel, question: StudyQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pregunta \(viewModel.currentIndex + 1) de \(viewModel.questionCount)")
                        .font(.headline)
                    ProgressView(value: Double(viewModel.currentIndex + 1), total: Double(viewModel.questionCount))
                        .accessibilityLabel("Progreso del repaso de errores")
                }

                Text(question.category)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if let imageName = question.imageName, let image = UIImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Imagen de la pregunta")
                }

                Text(question.question)
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    ForEach(question.answers) { answer in
                        answerOption(answer, question: question, viewModel: viewModel)
                    }
                }

                if viewModel.hasCheckedAnswer {
                    feedback(for: question, isCorrect: viewModel.checkedAnswerIsCorrect)
                }

                Button {
                    if viewModel.hasCheckedAnswer {
                        viewModel.advance()
                    } else {
                        do {
                            _ = try viewModel.checkAnswer(in: modelContext)
                        } catch {
                            print("No se pudo guardar el repaso de \(question.id): \(error)")
                            actionError = error.localizedDescription
                        }
                    }
                } label: {
                    Text(viewModel.hasCheckedAnswer
                         ? (viewModel.currentIndex == viewModel.questionCount - 1 ? "FINALIZAR REPASO" : "SIGUIENTE PREGUNTA")
                         : "COMPROBAR RESPUESTA")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasCheckedAnswer && viewModel.selectedAnswer == nil)
            }
            .padding(20)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func answerOption(_ answer: AnswerOption, question: StudyQuestion, viewModel: ErrorReviewViewModel) -> some View {
        let selected = viewModel.selectedAnswer == answer.id
        let correct = answer.id == question.correctAnswer
        let reveal = viewModel.hasCheckedAnswer

        return Button {
            viewModel.selectAnswer(answer.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(answer.id)
                    .font(.headline)
                    .frame(width: 30, height: 30)
                    .background(selected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.10), in: Circle())
                VStack(alignment: .leading, spacing: 7) {
                    Text(answer.text)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if reveal && selected && correct {
                        Label("Tu respuesta correcta", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    } else if reveal && selected {
                        Label("Tu respuesta · incorrecta", systemImage: "xmark.circle.fill").foregroundStyle(.red)
                    } else if reveal && correct {
                        Label("Respuesta correcta", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
                .font(.subheadline.weight(.medium))
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(optionBackground(selected: selected, correct: correct, reveal: reveal))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(optionBorder(selected: selected, correct: correct, reveal: reveal), lineWidth: selected || (reveal && correct) ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(reveal)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func feedback(for question: StudyQuestion, isCorrect: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(isCorrect ? "Respuesta correcta" : "Respuesta incorrecta", systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(isCorrect ? .green : .red)
            Text("EXPLICACIÓN")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(question.explanation)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func messageState(title: String, message: String, symbol: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.largeTitle).foregroundStyle(.secondary)
            Text(title).font(.headline).multilineTextAlignment(.center)
            Text(message).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Volver") { dismiss() }.buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadQuestionsIfNeeded() {
        guard viewModel == nil, loadError == nil else { return }
        do {
            let bank = try QuestionRepository().loadQuestions()
            let statistics = questionStatistics.map {
                QuestionStatistics(
                    questionID: $0.questionID,
                    timesAnswered: $0.timesAnswered,
                    correctCount: $0.correctCount,
                    incorrectCount: $0.incorrectCount
                )
            }
            let questions = ErrorReviewGenerator().selectQuestions(from: bank, statistics: statistics)
            guard !questions.isEmpty else {
                viewModel = ErrorReviewViewModel(questions: [])
                return
            }
            viewModel = ErrorReviewViewModel(questions: questions)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func optionBackground(selected: Bool, correct: Bool, reveal: Bool) -> Color {
        if reveal && selected && !correct { return Color.red.opacity(0.09) }
        if reveal && correct { return Color.green.opacity(0.09) }
        if selected { return Color.accentColor.opacity(0.08) }
        return Color(uiColor: .secondarySystemBackground)
    }

    private func optionBorder(selected: Bool, correct: Bool, reveal: Bool) -> Color {
        if reveal && selected && !correct { return .red }
        if reveal && correct { return .green }
        if selected { return .accentColor }
        return Color.secondary.opacity(0.22)
    }
}
