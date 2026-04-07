import SwiftUI

public struct HistoryView: View {
    @ObservedObject private var store: WaterBarStore
    @State private var draftTodayTotal = ""

    public init(store: WaterBarStore) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Today") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current total")
                        Spacer()
                        Text(store.progressSummary)
                            .foregroundStyle(.secondary)
                    }

                    TextField("Today's total in ml", text: $draftTodayTotal)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(saveTodayTotal)

                    HStack {
                        Button("Save correction", action: saveTodayTotal)
                        Button("Reset to 0") {
                            draftTodayTotal = "0"
                            saveTodayTotal()
                        }
                        Spacer()
                    }
                }
                .padding(.top, 4)
            }

            GroupBox("History") {
                if store.history.isEmpty {
                    Text("No completed days yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    List(store.history) { record in
                        HStack {
                            Text(record.dayKey)
                                .monospacedDigit()
                            Spacer()
                            Text("\(record.totalMl) ml")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .frame(minHeight: 220)
                }
            }
        }
        .padding()
        .onAppear {
            draftTodayTotal = "\(store.todayTotalMl)"
            store.refreshForCurrentDay()
        }
        .onChange(of: store.todayTotalMl) { newValue in
            draftTodayTotal = "\(newValue)"
        }
    }

    private func saveTodayTotal() {
        let parsedValue = Int(draftTodayTotal.filter(\.isNumber)) ?? 0
        store.updateTodayTotal(to: parsedValue)
        draftTodayTotal = "\(store.todayTotalMl)"
    }
}
