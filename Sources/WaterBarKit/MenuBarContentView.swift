import AppKit
import SwiftUI

public struct MenuBarContentView: View {
    @ObservedObject private var store: WaterBarStore
    @Environment(\.openWindow) private var openWindow

    public init(store: WaterBarStore) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(store.todayTotalMl)")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Text("/ \(store.settings.dailyGoalMl) ml")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Text(store.todayRecord.dayKey)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            ProgressView(value: store.progressFraction)
                .tint(store.isGoalComplete ? .blue : .accentColor)

            Text(store.isGoalComplete ? "Goal complete" : "\(store.remainingMl) ml left")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button {
                    store.undoLastDrink()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(store.lastIncrementMl == nil)
                .modifier(PointingHandCursor())
                .help("Undo last drink")

                Button {
                    store.addDrink()
                } label: {
                    Text("+\(store.settings.defaultIncrementMl) ml")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .modifier(PointingHandCursor())
                .help("Add water")
            }

            if let lastSaveErrorDescription = store.lastSaveErrorDescription {
                Text("Save issue: \(lastSaveErrorDescription)")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Divider()

            HStack(spacing: 10) {
                Spacer()

                Button {
                    openWindow(id: "history")
                } label: {
                    Image(systemName: "book.closed")
                }
                .buttonStyle(.borderless)
                .modifier(PointingHandCursor())
                .help("History")

                Button {
                    openWindow(id: "settings")
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .modifier(PointingHandCursor())
                .help("Settings")

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .modifier(PointingHandCursor())
                .help("Quit")
            }
        }
        .font(.system(size: 13))
        .padding(14)
        .frame(width: 272)
        .onAppear {
            store.refreshForCurrentDay()
        }
    }
}

private struct PointingHandCursor: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
