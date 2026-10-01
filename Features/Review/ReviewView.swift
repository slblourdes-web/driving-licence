import SwiftUI
import UIKit

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let result: TestSessionSnapshot
    @State private var currentIndex = 0

    private var answer: TestAnswerSnapshot { result.answers[currentIndex] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Pregunta \(currentIndex + 1) de \(result.questionCount)")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                ProgressView(value: Double(currentIndex + 1), total: Double(result.questionCount))
                    .accessibilityLabel("Progreso de la revisión")
                    .accessibilityValue("Pregunta \(currentIndex + 1) de \(result.questionCount)")

                Text(answer.category)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)

                if let imageName = answer.imageName,
                   let image = UIImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Imagen de la pregunta")
                }

                Text(answer.questionText)
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(answer.answers) { option in
                        reviewOption(option)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("EXPLICACIÓN")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(answer.explanation)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

                if let source = answer.source, !source.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FUENTE")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text(source)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Button("Anterior") { currentIndex -= 1 }
                        .buttonStyle(.bordered)
                        .disabled(currentIndex == 0)
                        .frame(minHeight: 48)
                    Spacer(minLength: 8)
                    if currentIndex == result.questionCount - 1 {
                        Button("FINALIZAR REVISIÓN") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .frame(minHeight: 48)
                    } else {
                        Button("Siguiente") { currentIndex += 1 }
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
        .navigationTitle("Revisar examen")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func reviewOption(_ option: AnswerOption) -> some View {
        let isSelected = answer.selectedAnswer == option.id
        let isCorrectOption = answer.correctAnswer == option.id

        HStack(alignment: .top, spacing: 10) {
            Text(option.id)
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Color.secondary.opacity(0.10), in: Circle())
            VStack(alignment: .leading, spacing: 8) {
                Text(option.text)
                    .fixedSize(horizontal: false, vertical: true)
                if isSelected && isCorrectOption {
                    Label("Tu respuesta correcta", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if isSelected {
                    Label("Tu respuesta · incorrecta", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } else if isCorrectOption {
                    Label("Respuesta correcta", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(optionBackground(isSelected: isSelected, isCorrectOption: isCorrectOption))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(optionBorder(isSelected: isSelected, isCorrectOption: isCorrectOption), lineWidth: isSelected || isCorrectOption ? 2 : 1)
        }
    }

    private func optionBackground(isSelected: Bool, isCorrectOption: Bool) -> Color {
        if isSelected && !answer.isCorrect { return Color.red.opacity(0.09) }
        if isCorrectOption { return Color.green.opacity(0.09) }
        return Color(uiColor: .secondarySystemBackground)
    }

    private func optionBorder(isSelected: Bool, isCorrectOption: Bool) -> Color {
        if isSelected && !answer.isCorrect { return .red }
        if isCorrectOption { return .green }
        return Color.secondary.opacity(0.22)
    }
}
