//
//  CreateEntityView.swift
//  OneExampe
//
//  Created by Robin Enhorn on 2024-11-12.
//

import SwiftUI
import OneCloudyKitty

struct CreateEntityView: View {

    let controller: OneCloudController
    let subscriber: OneSubscriber<SomeEntity>

    @State var state: CloudState = .idle
    @State var autoDelete: Bool = true

    var body: some View {
        NavigationView {
            VStack {

                Toggle("Auto delete", isOn: $autoDelete).fixedSize()

                Text("State: \(state.rawValue)")
                Text("Subscribed records: \(subscriber.entities.count)")

                Button("Add Entity") {
                    buttonWasPressed()
                }.padding(8)

            }.navigationTitle("Create entity")
        }
    }

    private func buttonWasPressed() {
        Task {
            do {
                await waitIfUITest()

                state = .creating
                var entity = try await controller.create(entity: SomeEntity(name: "Some entity", age: 41))
                print("Created entity: \(entity.description)")

                await waitIfUITest()

                state = .updatingProperty
                entity = try await controller.updateProperty(entity: entity, property: \.age, value: 42)
                print("Updated entity property: \(entity.description)")

                await waitIfUITest()

                state = .updating
                entity.name = "Saved entity"
                entity = try await controller.save(entity: entity)
                print("Saved entity: \(entity.description)")

                try await Task.sleep(nanoseconds: 2_000_000_000)

                state = .fetchingEntities
                let entities: [SomeEntity] = try await controller.getAll()
                print("Fetched entities: \(entities.map{ $0.description })")

                await waitIfUITest()

                if autoDelete {
                    state = .deleting
                    entity = try await controller.delete(entity: entity)
                    print("Deleted entity: \(entity.description)")
                    await waitIfUITest()
                }

                state = .idle
            } catch let error {
                print(error)
                state = .error
            }
        }
    }

    func waitIfUITest() async {
        if ProcessInfo.processInfo.environment["UI_TESTING"] == "true" {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

}

extension CreateEntityView {

    enum CloudState: String {
        case idle = "Idle"
        case creating = "Creating"
        case updating = "Updating"
        case updatingProperty = "Updating property"
        case fetchingEntities = "Fetching entities"
        case deleting = "Deleting"
        case error = "Error"
    }

}
