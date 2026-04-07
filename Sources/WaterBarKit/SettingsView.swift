import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var store: WaterBarStore
    @State private var draftDailyGoal = ""
    @State private var draftDefaultIncrement = ""
    @State private var draftReminderInterval = ""

    public init(store: WaterBarStore) {
        self.store = store
    }

    public var body: some View {
        Form {
            Section("Daily Goal") {
                editableNumberRow(
                    title: "Goal",
                    text: $draftDailyGoal,
                    currentValue: "\(store.settings.dailyGoalMl) ml",
                    buttonTitle: "Save",
                    action: applyDailyGoal
                )

                Stepper("Adjust goal by 250 ml", value: Binding(
                    get: { store.settings.dailyGoalMl },
                    set: { store.updateDailyGoal(to: $0) }
                ), in: 250...10_000, step: 250)

                editableNumberRow(
                    title: "Default drink",
                    text: $draftDefaultIncrement,
                    currentValue: "\(store.settings.defaultIncrementMl) ml",
                    buttonTitle: "Save",
                    action: applyDefaultIncrement
                )

                Stepper("Adjust default drink by 50 ml", value: Binding(
                    get: { store.settings.defaultIncrementMl },
                    set: { store.updateDefaultIncrement(to: $0) }
                ), in: 50...2_000, step: 50)
            }

            Section("Reminders") {
                Toggle("Enable reminders", isOn: Binding(
                    get: { store.settings.remindersEnabled },
                    set: { store.setRemindersEnabled($0) }
                ))

                editableNumberRow(
                    title: "Interval",
                    text: $draftReminderInterval,
                    currentValue: "\(store.settings.reminderIntervalMinutes) min",
                    buttonTitle: "Save",
                    action: applyReminderInterval
                )
                .disabled(!store.settings.remindersEnabled)

                Stepper("Adjust interval by 15 min", value: Binding(
                    get: { store.settings.reminderIntervalMinutes },
                    set: { store.updateReminderInterval(to: $0) }
                ), in: 15...240, step: 15)
                .disabled(!store.settings.remindersEnabled)

                Text(store.reminderStatusText)
                    .font(.footnote)
                    .foregroundStyle(store.reminderPermissionDenied ? .red : .secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear(perform: syncDraftsFromStore)
        .onChange(of: store.settings.dailyGoalMl) { _ in
            draftDailyGoal = "\(store.settings.dailyGoalMl)"
        }
        .onChange(of: store.settings.defaultIncrementMl) { _ in
            draftDefaultIncrement = "\(store.settings.defaultIncrementMl)"
        }
        .onChange(of: store.settings.reminderIntervalMinutes) { _ in
            draftReminderInterval = "\(store.settings.reminderIntervalMinutes)"
        }
    }

    @ViewBuilder
    private func editableNumberRow(
        title: String,
        text: Binding<String>,
        currentValue: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 96)
                .multilineTextAlignment(.trailing)
                .onSubmit(action)
            Button(buttonTitle, action: action)
        }

        HStack {
            Spacer()
            Text("Current: \(currentValue)")
                .foregroundStyle(.secondary)
                .font(.footnote)
                .monospacedDigit()
        }
    }

    private func syncDraftsFromStore() {
        draftDailyGoal = "\(store.settings.dailyGoalMl)"
        draftDefaultIncrement = "\(store.settings.defaultIncrementMl)"
        draftReminderInterval = "\(store.settings.reminderIntervalMinutes)"
    }

    private func applyDailyGoal() {
        store.updateDailyGoal(to: Int(draftDailyGoal.filter(\.isNumber)) ?? store.settings.dailyGoalMl)
    }

    private func applyDefaultIncrement() {
        store.updateDefaultIncrement(to: Int(draftDefaultIncrement.filter(\.isNumber)) ?? store.settings.defaultIncrementMl)
    }

    private func applyReminderInterval() {
        store.updateReminderInterval(to: Int(draftReminderInterval.filter(\.isNumber)) ?? store.settings.reminderIntervalMinutes)
    }
}
