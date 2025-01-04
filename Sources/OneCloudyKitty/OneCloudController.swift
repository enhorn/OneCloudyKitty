//
//  CloudController.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-08.
//

import SwiftUI
import CloudKit

/// Controller for interacting with the database.
@MainActor public class OneCloudController {

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
    
    /// Deletes the given entities.
    /// - Parameter entities: Entities to delete.
    /// - Returns: Arrays of `Result<CKRecord.ID, OneCloudController.Error>`. Discardable.
    @discardableResult func delete<Entity: OneRecordable>(entities: [Entity]) async throws(OneCloudController.Error) -> [Result<CKRecord.ID, OneCloudController.Error>] {
        guard !entities.isEmpty else { return [] }
        do {
            let modifyResult = try await database.modifyRecords(saving: [], deleting: entities.map(\.recordID))

            var mappedResult: [Result<CKRecord.ID, OneCloudController.Error>] = modifyResult.deleteResults.map { recordID, deleteResult in
                switch deleteResult {
                    case .success: .success(recordID)
                    case .failure(let error): .failure(.couldNotDeleteRecord(error))
                }
            }

            notifySubscriptions()
            return mappedResult
        } catch let error {
            throw .couldNotSaveRecords(error)
        }
    }

    /// Updates an ``OneRecordable`` entity's record in the CloudKit database.
    /// - Parameters:
    ///   - entity: The ``OneRecordable`` entity.
    /// - Returns: The updated ``OneRecordable`` entity. Discardable.
    @discardableResult func save<Entity: OneRecordable>(entity: Entity) async throws(OneCloudController.Error) -> Entity {
        do {
            let record = try await database.record(for: entity.recordID)
            let toSave = entity.update(record: record)

            if let storable = toSave as? any OneRecordableStorable {
                storable.changeDate = .now
            }

            let savedRecord = try await database.save(toSave)
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
    
    /// Saves the updates of the given entities.
    /// - Parameters:
    ///   - entities: Entities to save.
    ///   - savePolicy: Save policy. Defualts to `.ifServerRecordUnchanged`.
    /// - Returns: Array of `Result<Entity, OneCloudController.Error>`. Discardable.
    @discardableResult func save<Entity: OneRecordable>(
        entities: [Entity],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged
    ) async throws(OneCloudController.Error) -> [Result<Entity, OneCloudController.Error>] {
        guard !entities.isEmpty else { return [] }
        do {
            let recordsToSave = try await fetchRecords(for: entities)

            for record in recordsToSave {
                (entities.first(where: { $0.recordID == record.recordID }))?.update(record: record)
            }

            let modifyResult = try await database.modifyRecords(saving: recordsToSave, deleting: [], savePolicy: savePolicy)

            let mappedResult: [Result<Entity, OneCloudController.Error>] = try modifyResult.saveResults.map { modifyResult in
                switch modifyResult.value {
                    case .success(let record):
                        if let entity = Entity(record) {
                            return .success(entity)
                        } else {
                            throw Error.savedRecordLacksData
                        }
                    case .failure(let error):
                        return .failure(.couldNotSaveRecords(error))
                }
            }

            notifySubscriptions()
            return mappedResult
        } catch let error {
            throw .couldNotSaveRecords(error)
        }
    }

    /// Fetches all ``OneRecordable`` entities from the CloudKit database with an optional predicate.
    /// - Parameters:
    ///   - predicate: Optional predicate. Default to `nil`.
    /// - Returns: An array of ``OneRecordable`` entities.
    func getAll<Entity: OneRecordable>(predicate: NSPredicate? = nil) async throws -> [Entity] {
        try await fetchAll(fetchInfo: .initial(predicate))
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

// MARK: - Pagination fetching -

fileprivate typealias CloudKitFetchResult = Result<(matchResults: [(CKRecord.ID, Result<CKRecord, any Swift.Error>)], queryCursor: CKQueryOperation.Cursor?), any Swift.Error>

fileprivate enum OneFetchInfo {
    case initial(NSPredicate?)
    case more(CKQueryOperation.Cursor)
}

fileprivate enum OneFetchResult<Entity: OneRecordable>: @unchecked Sendable {
    case all([Entity])
    case hasMore([Entity], CKQueryOperation.Cursor)
    case error(OneCloudController.Error)
}

private extension OneCloudController {

    private func fetchAll<Entity: OneRecordable>(fetchInfo: OneFetchInfo) async throws -> [Entity] {
        try await withCheckedThrowingContinuation { continuation in

            @MainActor func checkForMore(result: CloudKitFetchResult, continuation: CheckedContinuation<[Entity], any Swift.Error>) async throws {
                let res: OneFetchResult<Entity> = handleFetch(result: result)
                switch res {
                    case .all(let entities):
                        continuation.resume(with: .success(entities))
                    case .hasMore(let entities, let cursor):
                        let next: [Entity] = try await fetchAll(fetchInfo: .more(cursor))
                        DispatchQueue.main.async {
                            continuation.resume(with: .success(entities + next))
                        }
                    case .error(let error):
                        continuation.resume(with: .failure(error))
                }
            }

            switch fetchInfo {
                case .initial(let predicate):
                    database.fetch(withQuery: CKQuery(recordType: Entity.recordType, predicate: predicate ?? NSPredicate(value: true))) { result in
                        Task { @MainActor in
                            try await checkForMore(result: result, continuation: continuation)
                        }
                    }
                case .more(let cursor):
                    database.fetch(withCursor: cursor) { result in
                        Task { @MainActor in
                            try await checkForMore(result: result, continuation: continuation)
                        }
                    }
            }
        }
    }

}

fileprivate func handleFetch<Entity: OneRecordable>(result: CloudKitFetchResult) -> OneFetchResult<Entity> {
    switch result {
        case .success(let records):
            do {
                let entities = try records.matchResults.compactMap { Entity(try $0.1.get()) }
                if let cursor = records.queryCursor {
                    return .hasMore(entities, cursor)
                } else {
                    return .all(entities)
                }
            } catch let error {
                return .error(OneCloudController.Error.other(error))
            }
        case .failure(let error):
            return .error(OneCloudController.Error.couldNotFetchRecords(error))
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

private extension OneCloudController {

    func fetchRecords<Entity: OneRecordable>(for entities: [Entity]) async throws -> [CKRecord] {
        let recordIDs = entities.map(\.recordID)
        return try await withUnsafeThrowingContinuation { callback in
            Task { @Sendable in
                try await database.fetch(withRecordIDs: recordIDs) { result in
                    switch result {
                        case .success(let recordResults):
                            callback.resume(with: .success(recordResults.compactMap { key, result in
                                if case .success(let record) = result {
                                    return record
                                } else {
                                    return nil
                                }
                            }))
                        case .failure(let error):
                            callback.resume(throwing: error)
                    }
                }
            }
        }
    }

}

fileprivate func setter<Entity: OneRecordable, Value>(for entity: Entity, keyPath: ReferenceWritableKeyPath<Entity, Value>) -> (Value) -> Void {
    { [weak entity] value in
        entity?[keyPath: keyPath] = value
    }
}

extension OneCloudController: @unchecked Sendable { }
