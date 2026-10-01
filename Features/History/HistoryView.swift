import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Query(sort: \StudyTestRecord.date, order: .reverse) private var tests: [StudyTestRecord]
    let onOpenTest: (TestSessionSnapshot) -> Void

    var body: some View {
        historyContent
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var historyContent: some View {
        if tests.isEmpty {
            emptyState
        } else {
            testList
        }
    }

    private var emptyState: some View {
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
    }

    private var testList: some View {
        List {
            ForEach(tests) { test in
                testRow(test)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func testRow(_ test: StudyTestRecord) -> some View {
        Button {
            onOpenTest(test.snapshot)
        } label: {
            historyRowContent(for: test)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }

    private func historyRowContent(for test: StudyTestRecord) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 9) {
                Text(test.date.formatted(date: .long, time: .shortened))
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

    private func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }
}
