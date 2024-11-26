//
//  GenericFormView.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-26.
//

import SwiftUI
import OneCloudyKitty

struct GenericFormView: View {

    enum Sheet: Equatable {
        case none
        case new
        case newChild(OneGenericEntity)
    }

    // Temporary model for the input form.
    @Observable class NewItem {
        var title: String = ""
        var date: Date = Date.now
        var integer: Int = 1
        var double: Double = 0.5
        func data() -> [String: OneGenericEntity.DataType] {
            ["title": .string(title), "date": .date(date), "integer": .integer(integer), "double": .double(double)]
        }
    }

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    @State var sheet: Sheet = .none

    let controller: OneCloudController
    @State var database: OneGenericStoredSubscriber

    @State var showNewItem: Bool = false
    @State var newItem: NewItem = NewItem()

    init(controller: OneCloudController) {
        self.controller = controller
        self.database = try! .genericStoredSubscriber(
            containerURL: URL.applicationSupportDirectory.appendingPathComponent("Test/database.sqlite"),
            controller: controller,
            pullInterval: 5,
            debugLogging: true
        )

        database.subscribeToChanges { entities in
            print(entities)
        }
    }

    var body: some View {
        NavigationView {
            List(database.entities) { entity in
                if database.entities.parent(for: entity) == nil {
                    if entity.children.isEmpty {
                        entityListViewContent(for: entity)
                            .swipeActions { addChildButton(for: entity) }
                    } else {
                        NavigationLink(
                            destination: { detailView(for: entity) },
                            label: { entityListViewContent(for: entity) }
                        ).swipeActions { addChildButton(for: entity) }
                    }
                }
            }.toolbar { newEntityButton() }
        }
        .navigationTitle("Generic form")
        .onAppear {
            database.start()
        }
        .sheet(isPresented: Binding(get: { sheet != .none }, set: { _ in })) {
            SheetView {
                NewEntityFormView(
                    newItem: $newItem,
                    onCancel: { self.sheet = .none },
                    onAdd: {
                        Task {
                            try await addEntity()
                        }
                    }
                )
            }
        }
    }

}

private extension GenericFormView {

    func entityListViewContent(for entity: OneGenericEntity) -> some View {
        VStack(spacing: 4) {

            HStack(spacing: .zero) {

                if let title = entity[string: "title"] {
                    if entity.children.isEmpty {
                        Text(title)
                    } else {
                        Text("\(title)  (\(database.entities.children(for: entity).count))")
                    }
                }
                if let date = entity[date: "date"] {
                    Spacer(minLength: 16)
                    Text(formatter.string(from: date))
                }
            }

            HStack(spacing: .zero) {
                if let integer = entity[integer: "integer"] {
                    Text("integer: \(integer)")
                }
                if let double = entity[double: "double"] {
                    Spacer(minLength: 16)
                    Text("double: \(String(format: "%.2f", double))")
                }
            }

        }
    }

    func detailView(for entity: OneGenericEntity) -> some View {
        List(database.entities.children(for: entity)) { child in
            entityListViewContent(for: child)
        }
    }

    func addChildButton(for entity: OneGenericEntity) -> some View {
        Button("Add child") {
            newItem = NewItem()
            sheet = .newChild(entity)
        }
    }

    func newEntityButton() -> some View {
        Button("New Item") {
            newItem = NewItem()
            sheet = .new
        }
    }

}

private extension GenericFormView {

    func addEntity() async throws {
        defer { self.sheet = .none }
        if case .newChild(let entity) = sheet {
            _ = try await addNewChild(to: entity)
        } else {
            _ = try await addNewEntity()
        }
    }

    func addNewEntity() async throws -> OneGenericEntity {
        try await database.controller.create(entity: OneGenericEntity(data: newItem.data()))
    }

    func addNewChild(to entity: OneGenericEntity) async throws -> OneGenericEntity {
        let child = try await database.controller.create(entity: OneGenericEntity(data: newItem.data()))
        entity.children.append(child.recordID)
        try await database.controller.save(entity: entity)
        return child
    }

}
