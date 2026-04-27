import SwiftUI

struct ChallengeDetail: View {
    @EnvironmentObject private var labStore: LabStore
    let challenge: LabChallenge

    private var noteBinding: Binding<String> {
        Binding(
            get: { labStore.note(for: challenge.id) },
            set: { labStore.updateNote($0, for: challenge.id) }
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(challenge.title)
                            .font(.largeTitle.weight(.bold))
                        Spacer()
                        Button {
                            labStore.toggleCompletion(for: challenge)
                        } label: {
                            Label(
                                labStore.isCompleted(challenge) ? "Complete" : "Mark Complete",
                                systemImage: labStore.isCompleted(challenge) ? "checkmark.circle.fill" : "checkmark.circle"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(labStore.isCompleted(challenge) ? .green : .accentColor)
                    }

                    Text(challenge.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text(challenge.objective)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }

                HStack(spacing: 10) {
                    StatusPill(text: challenge.category, systemImage: "square.grid.2x2")
                    StatusPill(text: challenge.difficulty, systemImage: "gauge.with.dots.needle.33percent")
                    StatusPill(text: challenge.attackSurface, systemImage: "scope")
                }

                LabSection(title: "Risk Model", systemImage: "exclamationmark.triangle") {
                    Text(challenge.risk)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }

                LabSection(title: "Practice", systemImage: "hammer") {
                    Text(challenge.practice)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }

                LabConsole(challenge: challenge)
                    .id("lab-actions")

                LabSection(title: "What To Inspect", systemImage: "magnifyingglass") {
                    BulletList(items: challenge.inspectHints, systemImage: "magnifyingglass")
                }

                LabSection(title: "Evidence To Capture", systemImage: "doc.text.magnifyingglass") {
                    BulletList(items: challenge.evidencePrompts, systemImage: "camera.viewfinder")
                }

                LabSection(title: "Completion Checklist", systemImage: "checklist") {
                    BulletList(items: challenge.completionCriteria, systemImage: "checkmark.circle")
                }

                LabSection(title: "Safer Pattern", systemImage: "lock.shield") {
                    Text(challenge.saferPattern)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }

                LabSection(title: "Portfolio Takeaway", systemImage: "star.leadinghalf.filled") {
                    Text(challenge.portfolioTakeaway)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }

                LabSection(title: "Study Notes", systemImage: "note.text") {
                    TextEditor(text: noteBinding)
                        .font(.body)
                        .frame(minHeight: 130)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.labTextBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                LabSection(title: "Report", systemImage: "doc.text") {
                    HStack {
                        Button {
                            labStore.generateReport(challenges: LabChallenge.seed)
                        } label: {
                            Label("Generate Markdown Report", systemImage: "doc.badge.gearshape")
                        }

                        Button {
                            labStore.copyReportToClipboard()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .disabled(labStore.report.isEmpty)
                    }

                    if !labStore.report.isEmpty {
                        ConsoleOutput(text: labStore.report, minHeight: 180)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .leading)
            }
            .onAppear {
                guard AppLaunchOptions.shouldFocusDemoOutput else {
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo("lab-actions", anchor: .top)
                    }
                }
            }
        }
        .background(Color.labWindowBackground)
    }
}
