import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ChallengeDetail: View {
    @EnvironmentObject private var labStore: LabStore
    @State private var isExportingSanitizedReport = false
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
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Button {
                                labStore.generateReport(challenges: LabChallenge.seed)
                            } label: {
                                Label("Generate Markdown", systemImage: "doc.badge.gearshape")
                            }

                            Button {
                                labStore.copyReportToClipboard()
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .disabled(labStore.report.isEmpty)
                        }

                        HStack {
                            Button {
                                labStore.generateSanitizedReport(challenges: LabChallenge.seed)
                            } label: {
                                Label("Prepare Sanitized", systemImage: "wand.and.stars")
                            }

                            Button {
                                isExportingSanitizedReport = true
                            } label: {
                                Label("Export .md", systemImage: "square.and.arrow.up")
                            }
                            .disabled(labStore.sanitizedReport.isEmpty)
                        }
                    }
                    .buttonStyle(.bordered)

                    if !labStore.reportExportStatus.isEmpty {
                        Label(labStore.reportExportStatus, systemImage: "checkmark.shield")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    if !labStore.report.isEmpty {
                        ConsoleOutput(text: labStore.report, minHeight: 180)
                    }

                    if !labStore.sanitizedReport.isEmpty {
                        ConsoleOutput(text: labStore.sanitizedReport, minHeight: 180)
                    }
                }
                .id("report")
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .leading)
            }
            .onAppear {
                guard let focusAnchorID = AppLaunchOptions.demoFocusAnchorID else {
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(focusAnchorID, anchor: .top)
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $isExportingSanitizedReport,
            document: MarkdownReportDocument(text: labStore.sanitizedReport),
            contentType: .markdownReport,
            defaultFilename: "iOSAppHackingLab-Sanitized-Study-Report.md",
            onCompletion: labStore.handleSanitizedReportExport
        )
        .background(Color.labWindowBackground)
    }
}

struct MarkdownReportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.markdownReport]
    }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        text = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

extension UTType {
    static var markdownReport: UTType {
        UTType(filenameExtension: "md") ?? .plainText
    }
}
