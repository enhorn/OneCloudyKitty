//
//  ContentView.swift
//  OneExampe
//
//  Created by Robin Enhorn on 2024-11-12.
//

import SwiftUI
import OneCloudyKitty

struct ContentView: View {

    let controller = OneCloudController(database: .public, containerID: "iCloud.SomeTestContainer")
    let subscriber: OneSubscriber<SomeEntity>
    let storedSubscriber: OneStoredSubscriber<SomeEntity.StorageModel, SomeEntity>

    @State var tab: String = "Create"

    init () {
        subscriber = OneSubscriber<SomeEntity>(controller: controller, pullInterval: 5)
        subscriber.subscribeToChanges { entities in
            print("Manually subscribed entities count: \(entities.count)")
        }

        storedSubscriber = try! OneStoredSubscriber<SomeEntity.StorageModel, SomeEntity>(
            containerURL: URL.documentsDirectory.appendingPathComponent("Test/database.sqlite"),
            controller: controller,
            pullIntervall: 5,
            debugLogging: true,
            updateModel: { model, entity in
                model.name = entity.name
                model.age = entity.age
                model.changeDate = entity.changeDate
            },
            updateEntity: { entity, model in
                entity.name = model.name
                entity.age = model.age
                entity.changeDate = model.changeDate
            }
        )

        storedSubscriber.subscribeToChanges { storedEntities in
            print("Manually subscribed stored entities count: \(storedEntities.count)")
        }
    }

    var body: some View {
        TabView {
            CreateEntityView(controller: controller, subscriber: subscriber)
                .tabItem {
                    VStack {
                        Image(systemName: "plus")
                        Text("Create")
                    }
                }
            EntitiesList(subscriber: subscriber)
                .tabItem {
                    VStack {
                        Image(systemName: "list.bullet")
                        Text("Entities (\(subscriber.entities.count))")
                    }
                }
        }.onAppear {
            subscriber.start()
            storedSubscriber.start()
        }
    }

}

extension NSPredicate: @retroactive @unchecked Sendable { }

#Preview {
    ContentView()
}
