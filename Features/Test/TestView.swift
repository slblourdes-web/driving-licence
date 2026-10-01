import SwiftUI
import UIKit
import SwiftData

struct TestView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TestViewModel
    let onExit: () -> Void

    @State private var showUnansweredAlert = false
    @State private var showFinishConfirmation = false
    @State private var showExitConfirmation = false
    @State private var saveError: String?

    var body: some View {
        Group {
            if let result = viewModel.evaluatedResult {
                ResultsView(result: result, onHome: onExit)
            } else {
                questionView
            }
        }
        .navigationTitle(viewModel.evaluatedResult == nil ? "Nuevo test" : "Resultados")
        .navigationBarTitleDisplayMode(.inline)
        // La salida controlada limpia el ViewModel al regresar a Home, también después de finalizar.
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if viewModel.evaluatedResult == nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Salir") { showExitConfirmation = true }
                }
            }
        }
        .confirmationDialog("¿Quieres salir del test?", isPresented: $showExitConfirmation, titleVisibility: .visible) {
            Button("Salir", role: .destructive, action: onExit)
            Button("Seguir con el test", role: .cancel) {}
        } message: {
            Text("Perderás las respuestas de este intento.")
        }
        .confirmationDialog("¿Quieres finalizar el examen?", isPresented: $showFinishConfirmation, titleVisibility: .visible) {
            Button("Finalizar") { finalizeTest() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Después de finalizar ya no podrás cambiar tus respuestas.")
        }
        .alert("No se pudo guardar el examen", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("Volver al test", role: .cancel) { saveError = nil }
        } message: {
            Text(saveErrorMessage)
        }
    }

    private var questionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pregunta \(viewModel.currentIndex + 1) de \(viewModel.questionCount)")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text("Respondidas: \(viewModel.answeredCount)/\(viewModel.questionCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ProgressView(value: viewModel.progress)
                        .accessibilityLabel("Progreso del test")
                        .accessibilityValue("Pregunta \(viewModel.currentIndex + 1) de \(viewModel.questionCount)")
                }

                Text(viewModel.currentQuestion.category)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)

                if let imageName = viewModel.currentQuestion.imageName,
                   let image = UIImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Imagen de la pregunta")
                }

                Text(viewModel.currentQuestion.question)
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    ForEach(viewModel.currentQuestion.answers) { answer in
                        answerButton(answer)
                    }
                }

                HStack(spacing: 12) {
                    Button("Anterior") { viewModel.goToPreviousQuestion() }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.currentIndex == 0)
                        .frame(minHeight: 48)
                    Spacer(minLength: 0)
                    if viewModel.currentIndex == viewModel.questionCount - 1 {
                        Button("FINALIZAR TEST") { requestFinish() }
                            .buttonStyle(.borderedProminent)
                            .frame(minHeight: 48)
                    } else {
                        Button("Siguiente") { viewModel.goToNextQuestion() }
                            .buttonStyle(.borderedProminent)
                            .frame(minHeight: 48)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .alert("Preguntas sin responder", isPresented: $showUnansweredAlert) {
            Button("Ir a la primera pendiente") { viewModel.goToFirstUnansweredQuestion() }
            Button("Seguir con el test", role: .cancel) {}
        } message: {
            Text(unansweredMessage)
        }
    }

    private var unansweredMessage: String {
        let count = viewModel.unansweredCount
        return count == 1 ? "Todavía tienes 1 pregunta sin responder." : "Todavía tienes \(count) preguntas sin responder."
    }

    private var saveErrorMessage: String {
        guard let saveError else {
            return "Tus respuestas siguen en esta sesión y no se mostrarán resultados hasta que el guardado termine."
        }
        return "Tus respuestas siguen en esta sesión y no se mostrarán resultados hasta que el guardado termine. \(saveError)"
    }

    @ViewBuilder
    private func answerButton(_ answer: AnswerOption) -> some View {
        let isSelected = viewModel.selectedAnswer(for: viewModel.currentQuestion) == answer.id
        Button {
            viewModel.selectAnswer(answer.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(answer.id)
                    .font(.headline)
                    .frame(width: 30, height: 30)
                    .background(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.10), in: Circle())
                Text(answer.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .accessibilityLabel("Seleccionada")
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.22), lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func requestFinish() {
        guard viewModel.canFinish else {
            showUnansweredAlert = true
            return
        }
        showFinishConfirmation = true
    }

    @MainActor
    private func finalizeTest() {
        do {
            _ = try viewModel.finish(using: modelContext)
        } catch {
            print("No se pudo guardar el examen \(viewModel.questions.count) preguntas: \(error)")
            saveError = error.localizedDescription
        }
    }
}
