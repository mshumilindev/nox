import Foundation

enum NoxMorningSummaryPresenter {

    static func present(snapshot: NoxMorningContinuitySnapshot) -> NoxMorningSummary? {
        let lines = snapshot.lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }

        let headline = lines[0]
        let supporting = Array(lines.dropFirst().prefix(3))
        return NoxMorningSummary(
            snapshot: snapshot,
            headline: headline,
            supportingLines: supporting
        )
    }
}
