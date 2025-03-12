//
//  ContentView.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var beverageRecords: [BeverageRecord]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(beverageRecords) { record in
                    NavigationLink {
                        Text("Record at \(record.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(record.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: deleteSelection) {
                        Label("Delete", systemImage: "trash")
                    }
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newRecord = BeverageRecord(timestamp: Date(), type: BeverageType.coffee)
            modelContext.insert(newRecord)
        }
    }

    private func deleteSelection() {
        if let record = beverageRecords.first {
            modelContext.delete(record)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(beverageRecords[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BeverageRecord.self, inMemory: true)
}
