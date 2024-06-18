//
//  ContentView.swift
//  QueriedTester
//
//  Created by Juan Arzola on 6/16/24.
//

import SwiftUI
import SwiftData
import Queried

@MainActor @Observable
private class ContentController {
    @Queried
    var items: [Item] = []

    func updates(in container: ModelContainer) async {
        do {
            for try await currItems in items(
                FetchDescriptor(predicate: .true),
                in: container.mainContext
            ) {
                print("\(#function): Got \(currItems.count) items")
            }
        } catch let error {
            print("\(#function): Error: \(error.localizedDescription)")
        }
    }
}

@MainActor
struct ContentView: View {
    // @Query private var items: [Item]
    @Environment(\.modelContext) private var modelContext
    @State private var controller: ContentController = ContentController()

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(controller.items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .task {
            await controller.updates(in: modelContext.container)
        }

    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
            try! modelContext.save()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(controller.items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
