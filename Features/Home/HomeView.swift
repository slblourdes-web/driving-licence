import SwiftUI
import UIKit

private enum HomeRoute: Hashable {
    case statistics
    case history
    case errorReview
    case historicalResult(TestSessionSnapshot)
}

struct HomeView: View {
    @State private var navigationPath = NavigationPath()
    @State private var testViewModel: TestViewModel?
    @State private var isTestPresented = false
    @State private var loadError: String?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Driving Study")
                            .font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text("Teórico de conducir · Países Bajos")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 12) {
                        Button(action: startNewTest) {
                            HomeActionLabel(
                                title: "Nuevo test",
                                subtitle: "Empieza una nueva práctica",
                                symbol: "play.fill",
                                prominent: true
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: HomeRoute.errorReview) {
                            HomeActionLabel(title: "Repasar errores", symbol: "arrow.counterclockwise")
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: HomeRoute.statistics) {
                            HomeActionLabel(title: "Estadísticas", symbol: "chart.bar.xaxis")
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: HomeRoute.history) {
                            HomeActionLabel(title: "Historial", symbol: "clock.arrow.circlepath")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .navigationTitle("Inicio")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .statistics:
                    StatisticsView()
                case .history:
                    HistoryView(onOpenTest: { navigationPath.append(HomeRoute.historicalResult($0)) })
                case .errorReview:
                    ErrorReviewView()
                case .historicalResult(let result):
                    ResultsView(result: result, onHome: { navigationPath = NavigationPath() })
                }
            }
            .navigationDestination(isPresented: $isTestPresented) {
                if let testViewModel {
                    TestView(viewModel: testViewModel, onExit: leaveTest)
                }
            }
            .alert("No se pudo iniciar el test", isPresented: Binding(
                get: { loadError != nil },
                set: { if !$0 { loadError = nil } }
            )) {
                Button("OK", role: .cancel) { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
    }

    private func startNewTest() {
        do {
            let bank = try QuestionRepository().loadQuestions()
            let questions = TestGenerator().selectQuestions(from: bank, requestedCount: 25)
            guard !questions.isEmpty else {
                loadError = "El banco de preguntas no contiene preguntas disponibles."
                return
            }
            testViewModel = TestViewModel(questions: questions)
            isTestPresented = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func leaveTest() {
        isTestPresented = false
        testViewModel = nil
    }
}

private struct HomeActionLabel: View {
    let title: String
    var subtitle: String? = nil
    let symbol: String
    var prominent = false
    var isDisabled = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .frame(width: 46, height: 46)
                .background(prominent ? Color.white.opacity(0.18) : Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color(uiColor: prominent ? UIColor.white.withAlphaComponent(0.82) : UIColor.secondaryLabel))
                }
            }
            Spacer(minLength: 8)
            if isDisabled {
                Text("Próximamente")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            } else if !prominent {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(Color(uiColor: prominent ? .white : .label))
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(prominent ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.primary.opacity(prominent ? 0 : 0.06), lineWidth: 1)
        }
        .opacity(isDisabled ? 0.65 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isDisabled ? [] : .isButton)
    }
}
