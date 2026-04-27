import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var labStore: LabStore
    @State private var selection: LabChallenge.ID? = LabChallenge.seed.first?.id

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 14) {
                SidebarProgress()
                    .padding(.horizontal, 12)
                    .padding(.top, 14)

                List(selection: $selection) {
                    Section("Labs") {
                        ForEach(LabChallenge.seed) { challenge in
                            ChallengeSidebarRow(challenge: challenge)
                                .tag(challenge.id)
                        }
                    }
                }
            }
            .navigationTitle("iOS App Hacking Lab")
        } detail: {
            if let challenge = LabChallenge.seed.first(where: { $0.id == selection }) {
                ChallengeDetail(challenge: challenge)
            } else {
                ContentUnavailableView("Choose a lab", systemImage: "lock.shield")
            }
        }
    }
}

struct SidebarProgress: View {
    @EnvironmentObject private var labStore: LabStore

    var body: some View {
        let completed = labStore.completedCount(in: LabChallenge.seed)
        let total = LabChallenge.seed.count

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Study Progress", systemImage: "chart.bar.fill")
                    .font(.headline)
                Spacer()
                Text("\(completed)/\(total)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: labStore.completionRatio(in: LabChallenge.seed))
                .progressViewStyle(.linear)

            Text("Local-only vulnerable labs for defensive iOS app security practice.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ChallengeSidebarRow: View {
    @EnvironmentObject private var labStore: LabStore
    let challenge: LabChallenge

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: labStore.isCompleted(challenge) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(labStore.isCompleted(challenge) ? .green : .secondary)

            VStack(alignment: .leading, spacing: 5) {
                Text(challenge.title)
                    .font(.headline)
                Text(challenge.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
