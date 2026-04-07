import SwiftUI
import WaterBarKit

@main
struct WaterBarApp: App {
    @NSApplicationDelegateAdaptor(WaterBarAppDelegate.self) private var appDelegate
    @StateObject private var store = WaterBarStore.live()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(store: store)
        } label: {
            Image(nsImage: WaterBarIcon.menuBarImage())
        }
        .menuBarExtraStyle(.window)

        WindowGroup("History", id: "history") {
            HistoryView(store: store)
                .frame(minWidth: 360, minHeight: 420)
        }

        WindowGroup("Settings", id: "settings") {
            SettingsView(store: store)
                .frame(minWidth: 380, minHeight: 320)
        }
    }
}
