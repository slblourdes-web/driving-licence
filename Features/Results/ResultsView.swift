import SwiftUI
import UIKit

struct ResultsView: View {
    let result: TestSessionSnapshot
    let onHome: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("RESULTADO")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(result.correctCount) / \(result.questionCount)")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .accessibilityLabel("\(result.correctCount) correctas de \(result.questionCount)")
                    Text(percent(result.correctPercentage))
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22))

                VStack(spacing: 12) {
                    Label("\(result.correctCount) correctas", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Label("\(result.incorrectCount) incorrectas", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.body.weight(.medium))
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

                NavigationLink {
                    ReviewView(result: result)
                } label: {
                    Text("REVISAR EXAMEN")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onHome) {
                    Text("VOLVER AL INICIO")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
            }
            .padding(20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle("Resultados")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }
}
