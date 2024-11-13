//
//  EntitiesList.swift
//  OneExampe
//
//  Created by Robin Enhorn on 2024-11-12.
//

import SwiftUI
import OneCloudyKitty

struct EntitiesList: View {

    let subscriber: OneSubscriber<SomeEntity>

    var body: some View {
        NavigationStack {
            List {
                Section(
                    content: {
                        ForEach(subscriber.entities) { entity in
                            EntitiesListItem(entity: entity) {
                                delete(entity: entity)
                            }
                        }
                    },
                    footer: {
                        Text("Swipe to delete")
                    }
                )
            }
            .navigationTitle("Subscribed entities")
            #if os(iOS)
            .listStyle(.grouped)
            #endif
        }
    }

    private func delete(entity: SomeEntity) {
        Task {
            do {
                try await subscriber.controller.delete(entity: entity)
                try await subscriber.refresh()
            } catch let error {
                print("Error deleting entity: \(error)")
            }

        }
    }

}

struct EntitiesListItem: View {

    let entity: SomeEntity
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(entity.name) {
            VStack {
                Text("Name: \(entity.name)")
                Text("Age: \(entity.age)")
            }
        }.swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

}
