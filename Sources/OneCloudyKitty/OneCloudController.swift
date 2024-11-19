//
//  CloudController.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-08.
//

import SwiftUI
import CloudKit

/// Controller for interacting with the database.
public class OneCloudController {

    private let container: CKContainer
    private let database: CKDatabase
    private var changeSubscriptions: [ChangeSubscription] = []

    /// - Parameters:
    ///   - database: Database to be used. Defalts to `.private`.
    ///   - containerID: CloudKit container ID.
    public init(database: Database = .private, containerID: String) {
        self.container = CKContainer(identifier: containerID)
        switch database {
            case .private: self.database = container.privateCloudDatabase
            case .public: self.database = container.publicCloudDatabase
            case .shared: self.database = container.sharedCloudDatabase
        }
    }

}

// MARK: - API -

public extension OneCloudController {

    /// Create a record and sync it with the CloudKit database..
    /// - Parameters:
    ///   - constructor: Contructor closure.
    /// - Returns: The ``OneRecordable`` entity that has been contructet from the CloudKit responce.
    func create<Entity: OneRecordable>(constructor: () -> Entity) async throws(OneCloudController.Error) -> Entity {
        try await create(entity: constructor())
    }

    /// Create a record and sync it with the CloudKit database..
    /// - Parameters:
    ///   - entity: The ``OneRecordable`` entity.
    /// - Returns: The ``OneRecordable`` entity that has been contructet from the CloudKit responce.
    func create<Entity: OneRecordable>(entity: Entity) async throws(OneCloudController.Error) -> Entity {
        do {
            let entityRecord = entity.generateNewRecord()
            let record = try await database.save(entityRecord)
            if let entity = Entity(record) {
                notifySubscriptions()
                return entity
            } else {
                throw Error.createdRecordLacksData
            }
        } catch let error {
            throw .couldNotCreateRecord(error)
        }
    }

    /// Deletes an ``OneRecordable`` entity's record from the CloudKit database.
    /// - Parameters:
    ///   - entity: The ``OneRecordable`` entity.
    /// - Returns: The deleted ``OneRecordable`` entity. Discardable.
    @discardableResult func delete<Entity: OneRecordable>(entity: Entity) async throws(OneCloudController.Error) -> Entity {
        do {
            try await database.deleteRecord(withID: entity.recordID)
            notifySubscriptions()
            return entity
        } catch let error {
            throw .couldNotDeleteRecord(error)
        }
    }

    /// Updates an ``OneRecordable`` entity's record in the CloudKit database.
    /// - Parameters:
    ///   - entity: The ``OneRecordable`` entity.
    /// - Returns: The updated ``OneRecordable`` entity. Discardable.
    @discardableResult func save<Entity: OneRecordable>(entity: Entity) async throws(OneCloudController.Error) -> Entity {
        do {
            let record = try await database.record(for: entity.recordID)
            let savedRecord = try await database.save(entity.update(record: record))
            if let entity = Entity(savedRecord) {
                notifySubscriptions()
                return entity
            } else {
                throw Error.savedRecordLacksData
            }
        } catch let error {
            throw .couldNotSaveRecord(error)
        }
    }

    /// Fetches all ``OneRecordable`` entities from the CloudKit database with an optional predicate.
    /// - Parameters:
    ///   - predicate: Optional predicate. Default to `nil`.
    /// - Returns: An array of ``OneRecordable`` entities.
    func getAll<Entity: OneRecordable>(predicate: NSPredicate? = nil) async throws -> [Entity] {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withQuery: CKQuery(recordType: Entity.recordType, predicate: predicate ?? NSPredicate(value: true))) { result in
                switch result {
                    case .success(let records):
                        do {
                            continuation.resume(returning: try records.matchResults.compactMap { Entity(try $0.1.get()) })
                        } catch let error {
                            continuation.resume(throwing: Error.other(error))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: Error.couldNotFetchRecords(error))
                }
            }
        }
    }

    /// Updates a property of a ``OneRecordable`` entity and saves it with the CloudKit database.
    /// - Parameters:
    ///   - entity: The ``OneRecordable`` entity to update.
    ///   - property: KeyPath to the property to update.
    ///   - value: Value to set.
    /// - Returns: The updated ``OneRecordable`` entity contructet from the CloudKit responce. Discardable.
    @discardableResult func updateProperty<Entity: OneRecordable, Value>(entity: Entity, property: ReferenceWritableKeyPath<Entity, Value>, value: Value) async throws(OneCloudController.Error) -> Entity {
        do {
            setter(for: entity, keyPath: property)(value)
            return try await save(entity: entity)
        } catch {
            throw .couldNotUpdateRecord
        }
    }

}

// MARK: - Internal subscriptions -

extension OneCloudController {

    internal struct ChangeSubscription {

        let queue: DispatchQueue
        let callback: () -> Void

        init(queue: DispatchQueue = .main, callback: @escaping () -> Void) {
            self.queue = queue
            self.callback = callback
        }

    }

    internal func subscribeToChanges(subscription: ChangeSubscription) {
        changeSubscriptions.append(subscription)
    }

    internal func subscribeToChanges(callback: @escaping () -> Void) {
        subscribeToChanges(subscription: ChangeSubscription(callback: callback))
    }

    private func notifySubscriptions() {
        changeSubscriptions.forEach {
            $0.queue.async(execute: DispatchWorkItem(block: $0.callback))
        }
    }

}

// MARK: - Support -

fileprivate func setter<Entity: OneRecordable, Value>(for entity: Entity, keyPath: ReferenceWritableKeyPath<Entity, Value>) -> (Value) -> Void {
    { [weak entity] value in
        entity?[keyPath: keyPath] = value
    }
}

extension OneCloudController: @unchecked Sendable { }
