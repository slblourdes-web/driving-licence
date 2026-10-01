import SwiftUI
import SwiftData

@main
struct DrivingStudyApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: StudyTestRecord.self, TestAnswerRecord.self, QuestionStatisticRecord.self)
        } catch {
            fatalError("No se pudo iniciar el almacenamiento local: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(container)
    }
}
