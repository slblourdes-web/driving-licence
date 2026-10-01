import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Query(sort: \StudyTestRecord.date, order: .reverse) private var tests: [StudyTestRecord]
    let onOpenTest: (TestSessionSnapshot) -> Void

    var body: some View {
        Group {
            if tests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text("Todavía no has realizado ningún test.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("Cuando termines un examen, aparecerá aquí.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(tests) { test in
                    Button {
                        onOpenTest(test.snapshot)
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 9) {
                                Text(test.date.formatted(date: .long, time: .short))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("\(test.correctCount)/\(test.questionCount)")
                                        .font(.title3.weight(.bold))
                                        .monospacedDigit()
                                    Spacer(minLength: 6)
                                    Text(percent(test.correctPercentage))
                                        .font(.headline.weight(.semibold))
                                        .monospacedDigit()
                                }
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }
}
