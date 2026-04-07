import AppKit
import SwiftUI

public struct MenuBarContentView: View {
    @ObservedObject private var store: WaterBarStore
    @Environment(\.openWindow) private var openWindow

    private enum AuxiliaryWindow: String {
        case history
        case settings

        var title: String {
            switch self {
            case .history:
                "History"
            case .settings:
                "Settings"
            }
        }
    }

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

            HStack(alignment: .bottom, spacing: 14) {
                CupProgressView(progress: store.progressFraction)
                    .frame(width: 62, height: 74)

                VStack(spacing: 8) {
                    Button {
                        store.addDrink()
                    } label: {
                        Text("+\(store.settings.defaultIncrementMl) ml")
                            .frame(maxWidth: .infinity, minHeight: 22)
                    }
                    .buttonStyle(.borderedProminent)
                    .modifier(PointingHandCursor())
                    .help("Add water")

                    Button {
                        store.undoLastDrink()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity, minHeight: 22)
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.todayTotalMl == 0)
                    .modifier(PointingHandCursor())
                    .help("Undo last drink")
                }
                .frame(maxWidth: .infinity, minHeight: 74, alignment: .bottom)
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
                    openAndFocusWindow(.history)
                } label: {
                    Image(systemName: "book.closed")
                }
                .buttonStyle(.borderless)
                .modifier(PointingHandCursor())
                .help("History")

                Button {
                    openAndFocusWindow(.settings)
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
        .frame(width: 248)
        .onAppear {
            store.refreshForCurrentDay()
        }
    }

    private func openAndFocusWindow(_ window: AuxiliaryWindow) {
        openWindow(id: window.rawValue)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            guard let targetWindow = NSApp.windows.first(where: { $0.title == window.title }) else {
                return
            }

            targetWindow.orderFrontRegardless()
            targetWindow.makeKeyAndOrderFront(nil)
        }
    }
}

private struct CupProgressView: View {
    let progress: Double
    private let cupImage = WaterBarIcon.progressCupImage()

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let interiorShape = CupInteriorShape()
            let interiorRect = CGRect(
                x: size.width * 0.23,
                y: size.height * 0.25,
                width: size.width * 0.54,
                height: size.height * 0.56
            )
            let fillHeight = interiorRect.height * clampedProgress
            let fillRect = CGRect(
                x: interiorRect.minX,
                y: interiorRect.maxY - fillHeight,
                width: interiorRect.width,
                height: fillHeight
            )
            let imageInsets = EdgeInsets(
                top: size.height * 0.02,
                leading: size.width * 0.02,
                bottom: size.height * 0.02,
                trailing: size.width * 0.02
            )

            ZStack {
                if fillHeight > 0.5 {
                    WaterFillShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.92),
                                    Color.blue.opacity(0.72),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: fillRect.width, height: fillRect.height)
                        .position(x: fillRect.midX, y: fillRect.midY)
                        .clipShape(interiorShape)

                    WaterWaveShape()
                        .stroke(Color.primary.opacity(0.78), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                        .frame(width: interiorRect.width * 0.96, height: 12)
                        .position(
                            x: size.width * 0.5,
                            y: max(interiorRect.minY + 4, fillRect.minY + 2)
                        )
                        .clipShape(interiorShape)
                }

                if let cupImage {
                    Image(nsImage: cupImage)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .padding(imageInsets)
                } else {
                    CupShape()
                        .stroke(Color.primary.opacity(0.8), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(width: size.width, height: size.height, alignment: .bottom)
        }
        .accessibilityLabel("Water intake progress")
    }
}

private struct CupShape: Shape {
    func path(in rect: CGRect) -> Path {
        let topY = rect.minY + rect.height * 0.11
        let bottomY = rect.maxY - rect.height * 0.06
        let leftTop = CGPoint(x: rect.minX + rect.width * 0.08, y: topY)
        let rightTop = CGPoint(x: rect.maxX - rect.width * 0.08, y: topY)
        let leftBottom = CGPoint(x: rect.minX + rect.width * 0.24, y: bottomY)
        let rightBottom = CGPoint(x: rect.maxX - rect.width * 0.24, y: bottomY)

        var path = Path()
        path.move(to: leftTop)
        path.addLine(to: rightTop)
        path.addCurve(
            to: rightBottom,
            control1: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.maxY - rect.height * 0.44),
            control2: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.81)
        )
        path.addCurve(
            to: leftBottom,
            control1: CGPoint(x: rect.maxX - rect.width * 0.40, y: rect.maxY + rect.height * 0.01),
            control2: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.maxY + rect.height * 0.01)
        )
        path.addCurve(
            to: leftTop,
            control1: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.81),
            control2: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.maxY - rect.height * 0.44)
        )
        path.closeSubpath()
        return path
    }
}

private struct CupInteriorShape: Shape {
    func path(in rect: CGRect) -> Path {
        let topY = rect.minY + rect.height * 0.06
        let bottomY = rect.maxY - rect.height * 0.02
        let leftTop = CGPoint(x: rect.minX + rect.width * 0.04, y: topY)
        let rightTop = CGPoint(x: rect.maxX - rect.width * 0.04, y: topY)
        let leftBottom = CGPoint(x: rect.minX + rect.width * 0.16, y: bottomY)
        let rightBottom = CGPoint(x: rect.maxX - rect.width * 0.16, y: bottomY)

        var path = Path()
        path.move(to: leftTop)
        path.addLine(to: rightTop)
        path.addCurve(
            to: rightBottom,
            control1: CGPoint(x: rect.maxX - rect.width * 0.02, y: rect.maxY - rect.height * 0.48),
            control2: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY + rect.height * 0.74)
        )
        path.addCurve(
            to: leftBottom,
            control1: CGPoint(x: rect.maxX - rect.width * 0.34, y: rect.maxY + rect.height * 0.01),
            control2: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY + rect.height * 0.01)
        )
        path.addCurve(
            to: leftTop,
            control1: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.74),
            control2: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.maxY - rect.height * 0.48)
        )
        path.closeSubpath()
        return path
    }
}

private struct WaterFillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 10, height: 10))
        return path
    }
}

private struct WaterWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.midY - rect.height * 0.18),
            control2: CGPoint(x: rect.maxX - rect.width * 0.26, y: rect.midY + rect.height * 0.12)
        )
        return path
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
