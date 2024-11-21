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

                VStack(spacing: 8) {
                    Button("Add Entity", action: addButtonWasPressed).disabled(state != .idle)
                    Button("Update all", action: updateButtonWasPressed).disabled(state != .idle)
                    Button("Delete all", action: deleteButtonWasPressed).disabled(state != .idle)
                }.padding(8)

            }.navigationTitle("Create entity")
        }
    }

    private func addButtonWasPressed() {
        Task {
            do {
                print("-----------------------------------------")
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

                await waitIfUITest()

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
                print("-----------------------------------------")
            } catch let error {
                print(error)
                state = .error
            }
        }
    }

    private func deleteButtonWasPressed() {
        Task {
            do {
                state = .deleting
                let results = try await controller.delete(entities: subscriber.entities)

                print("-----------------------------------------")
                for result in results {
                    switch result {
                        case .success(let id): print("Deleted: \(id.recordName)")
                        case .failure(let error): print("Failed to delete: \(error.localizedDescription)")
                    }
                }
                print("-----------------------------------------")

                state = .idle
            } catch let error {
                print(error)
                state = .error
            }
        }
    }

    private func updateButtonWasPressed() {
        Task {
            do {
                state = .deleting

                let toUpdate: [SomeEntity] = subscriber.entities.enumerated().map { index, entity in
                    entity.name = "\(entity) (updated \(index))"
                    return entity
                }

                let results = try await controller.save(entities: toUpdate)

                print("-----------------------------------------")
                for result in results {
                    switch result {
                        case .success(let entity): print("Updated: \(entity)")
                        case .failure(let error): print("Failed to update: \(error)")
                    }
                }
                print("-----------------------------------------")

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
