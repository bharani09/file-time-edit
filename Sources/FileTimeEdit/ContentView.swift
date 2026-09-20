import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HSplitView {
                selectionPane
                    .frame(minWidth: 360, idealWidth: 440)
                timestampPane
                    .frame(minWidth: 320, idealWidth: 360)
            }
            Divider()
            actionBar
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("File Time Edit")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text("Created and modified timestamps")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: model.chooseItems) {
                Label("Add Items", systemImage: "plus")
            }
            .keyboardShortcut("o", modifiers: .command)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private var selectionPane: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ITEMS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !model.selectedURLs.isEmpty {
                    Text("\(model.selectedURLs.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(action: model.clear) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Remove all items")
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            if model.selectedURLs.isEmpty {
                dropZone
            } else {
                List(model.selectedURLs, id: \.self) { url in
                    HStack(spacing: 10) {
                        Image(systemName: itemIcon(for: url))
                            .foregroundStyle(url.hasDirectoryPath ? Color.accentColor : .secondary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                            Text(url.deletingLastPathComponent().path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button {
                            model.remove(url)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .help("Remove \(url.lastPathComponent)")
                    }
                    .padding(.vertical, 3)
                }
                .listStyle(.inset)
                .dropDestination(for: URL.self) { urls, _ in
                    model.add(urls)
                    return true
                } isTargeted: { model.isDropTargeted = $0 }
                .overlay {
                    if model.isDropTargeted {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor, lineWidth: 3)
                            .padding(6)
                    }
                }
            }
        }
    }

    private var dropZone: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(model.isDropTargeted ? Color.accentColor : .secondary)
            Text("Drop files or folders here")
                .font(.headline)
            Button("Choose Files or Folders", action: model.chooseItems)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(model.isDropTargeted ? Color.accentColor.opacity(0.08) : .clear)
                .strokeBorder(
                    model.isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1.5, dash: [7])
                )
                .padding(18)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: model.chooseItems)
        .dropDestination(for: URL.self) { urls, _ in
            model.add(urls)
            return true
        } isTargeted: { model.isDropTargeted = $0 }
    }

    private var timestampPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("NEW TIMESTAMP")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Grid(horizontalSpacing: 12, verticalSpacing: 16) {
                GridRow {
                    NumericTimestampField(
                        title: "Year",
                        value: $model.year,
                        range: 1...9999
                    )
                    NumericTimestampField(
                        title: "Month",
                        value: $model.month,
                        range: 1...12
                    )
                    NumericTimestampField(
                        title: "Date",
                        value: $model.day,
                        range: 1...31
                    )
                }

                GridRow {
                    NumericTimestampField(
                        title: "Hours",
                        value: $model.hour,
                        range: 0...23
                    )
                    NumericTimestampField(
                        title: "Minutes",
                        value: $model.minute,
                        range: 0...59
                    )
                    NumericTimestampField(
                        title: "Seconds",
                        value: $model.second,
                        range: 0...59
                    )
                }
            }

            if model.selectedDate == nil {
                Label("Enter a valid date and time", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Divider()

            Toggle(isOn: $model.recursively) {
                Label("Include folder contents", systemImage: "folder.badge.gearshape")
            }
            .disabled(model.folderCount == 0)

            Spacer()

            resultSummary
        }
        .padding(18)
    }

    @ViewBuilder
    private var resultSummary: some View {
        if !model.results.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label(
                    "Updated \(model.successfulCount) item\(model.successfulCount == 1 ? "" : "s")",
                    systemImage: model.failedResults.isEmpty
                        ? "checkmark.circle.fill"
                        : "exclamationmark.triangle.fill"
                )
                .font(.headline)
                .foregroundStyle(model.failedResults.isEmpty ? .green : .orange)

                ForEach(model.failedResults.prefix(3)) { result in
                    Text("\(result.url.lastPathComponent): \(result.errorDescription ?? "Unknown error")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var actionBar: some View {
        HStack {
            Text(model.selectedURLs.isEmpty ? "No items selected" : timestampPreview)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: model.applyTimestamp) {
                if model.isApplying {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 18, height: 18)
                } else {
                    Label("Apply Timestamp", systemImage: "clock.arrow.2.circlepath")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(
                model.selectedURLs.isEmpty ||
                model.isApplying ||
                model.selectedDate == nil
            )
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private var timestampPreview: String {
        model.selectedDate?.formatted(
            .dateTime
                .year()
                .month(.abbreviated)
                .day()
                .hour()
                .minute()
                .second()
        ) ?? "Invalid date and time"
    }

    private func itemIcon(for url: URL) -> String {
        url.hasDirectoryPath ? "folder.fill" : "doc.fill"
    }
}

private struct NumericTimestampField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                TextField(
                    title,
                    value: $value,
                    format: .number.grouping(.never)
                )
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .monospacedDigit()

                Stepper(title, value: $value, in: range)
                    .labelsHidden()
            }
        }
        .frame(minWidth: 82)
    }
}