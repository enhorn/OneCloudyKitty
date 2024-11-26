//
//  OneStoredSubscriber.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-23.
//

import Foundation
import OneCloudyKitty
import SwiftData
import OSLog

/// Database backed subscriber for a list of entities implementing the ``OneRecordable`` protocol.
@Observable @MainActor final public class OneStoredSubscriber<StorageModel: OneRecordableStorageModel, Entity: OneRecordableStorable> {

    private var subscription: OneChangeSubscription<Entity>?
    private let container: ModelContainer
    private let deletionStategy: DeletionStategy
    private let subscriber: OneSubscriber<Entity>
    private let updateModel: UpdateModel
    private let updateEntity: UpdateEntity
    private var changeSubscriptions: [OneChangeSubscription<Entity>] = []
    private let logger: Logger?

    /// Controller used by the subscriber.
    public let controller: OneCloudController

    /// Current entities array. Reflects the contents of the database.
    /// Reflects what's stored in the database, so mind the ``DeletionStategy`` setting.
    private(set) public var entities: [Entity] {
        didSet { notifySubscriptions() }
    }

    /// - Parameters:
    ///   - containerURL: URL to the the container sqlite database.
    ///   - controller: ``OneCloudController`` controller to be used.
    ///   - deletionStategy: Deletion strategy. Defaults to `.remove`.
    ///   - pullInterval: Interval for pulling CloudKit changes. Defaults to `.oneDefaultPullInterval`.
    ///   - debugLogging: If debug logging should be performed. Defaults to `false`.
    ///   - updateModel: Closure for updating the model with changes from the entity. Relies on the `changeDate` property of the model & entity.
    ///   - updateEntity: Closure for updating the entity with changes from the model. Relies on the `changeDate` property of the model & entity.
    public init(
        containerURL: URL,
        controller: OneCloudController,
        deletionStategy: DeletionStategy = .remove,
        pullInterval: TimeInterval = .oneDefaultPullInterval,
        debugLogging: Bool = false,
        updateModel: @escaping UpdateModel,
        updateEntity: @escaping UpdateEntity
    ) throws {
        self.container = try ModelContainer(
            for: StorageModel.self,
            configurations: ModelConfiguration(
                String(describing: StorageModel.self),
                url: containerURL,
                cloudKitDatabase: .none
            )
        )
        self.controller = controller
        self.deletionStategy = deletionStategy
        self.subscriber = OneSubscriber<Entity>(controller: controller, pullInterval: pullInterval, debugLogging: debugLogging)
        self.updateModel = updateModel
        self.updateEntity = updateEntity
        self.entities = (try? Self.fetch(from: container)) ?? []
        self.logger = debugLogging ? Logger(subsystem: "com.enhorn.OneCloudyKitty", category: String(describing: Self.self)) : nil
    }

}

/// MARK: - API -

public extension OneStoredSubscriber {

    /// Starts CloudKit changes subscription.
    func start() {
        guard subscription == nil else { return }
        logger?.debug("Starting subscription.")
        subscribeToCloudKit()
        subscriber.start()
    }

    /// Stops CloudKit changes subscription.
    func stop() {
        logger?.debug("Stopping subscription.")
        unsubscribeFromCloudKit()
        subscriber.stop()
    }

    /// Manually refreshes the data. Does not the affect the timing of the scheduled pulling of data.
    func refresh() async throws {
        try await subscriber.refresh()
    }

    /// Subscribes to changes of the entities with a callback.
    /// - Parameter callback: To be called when entities changes.
    /// - Returns: ``OneSubscriber.ChangeSubscription``. Discardable.
    @discardableResult func subscribeToChanges(callback: @escaping ([Entity]) -> Void) -> OneChangeSubscription<Entity> {
        let subscription = OneChangeSubscription(callback: callback)
        subscribeToChanges(subscription: subscription)
        return subscription
    }

    /// Subscribes to changes of the entities.
    /// - Parameter subscription: Subscription object.
    /// - Returns: ``OneSubscriber.ChangeSubscription``. Discardable.
    @discardableResult func subscribeToChanges(subscription: OneChangeSubscription<Entity>) -> OneChangeSubscription<Entity> {
        changeSubscriptions.append(subscription)
        return subscription
    }

    /// Unsubscribes from change callbacks.
    /// - Parameter subscription: Subscription to unsubscribe.
    func unsubscribeFromChanges(subscription: OneChangeSubscription<Entity>) {
        changeSubscriptions.removeAll {
            $0.uuid == subscription.uuid
        }
    }

}

/// MARK: - Subscription handling -

private extension OneStoredSubscriber {

    func subscribeToCloudKit() {
        guard subscription == nil else { return }
        subscription = subscriber.subscribeToChanges { [weak self] entities in
            Task {
                do {
                    try await self?.updateDatabase(with: entities)
                } catch let error {
                    self?.logger?.error("Error updating database: \(error)")
                }
            }
        }
    }

    func unsubscribeFromCloudKit() {
        if let subscription {
            subscriber.unsubscribeFromChanges(subscription: subscription)
        }
        subscription = nil
    }

}

/// MARK: - Database handling -

private extension OneStoredSubscriber {

    func updateDatabase(with cloudKitEntities: [Entity]) async throws {
        let current = try container.mainContext.fetch(FetchDescriptor<StorageModel>())
        var updatedEntities: [Entity] = []

        for entity in cloudKitEntities {
            if let existingModel = current.first(where: { $0.recordID == entity.recordID.recordName }) {
                guard existingModel.changeDate != entity.changeDate else { logger?.debug("Same change date, no updates needed, skipping."); continue }
                if case .entity(let updatedEntity) = updateModelOrEntity(existingModel: existingModel, entity: entity) {
                    updatedEntities.append(updatedEntity)
                }
            } else {
                logger?.debug("Adding model to database.")
                container.mainContext.insert(entity.storageModel())
            }
        }

        try await subscriber.controller.save(entities: updatedEntities)

        handleDeletion(currentDataModels: current, cloudKitEntities: cloudKitEntities)

        if container.mainContext.hasChanges {
            logger?.debug("Saving database changes.")
            try container.mainContext.save()
        }

        entities = try Self.fetch(from: container)
    }

    func handleDeletion(currentDataModels: [StorageModel], cloudKitEntities: [Entity]) {
        switch deletionStategy {
            case .ignore: break
            case .remove:
                let modelsToDelete = currentDataModels.filter { model in
                    !cloudKitEntities.contains(where: { $0.recordID.recordName == model.recordID })
                }
                if !modelsToDelete.isEmpty {
                    logger?.debug("Deleting \(modelsToDelete.count) models that has been removed from CloudKit.")
                    for model in modelsToDelete {
                        container.mainContext.delete(model)
                    }
                }
        }
    }

    func updateModelOrEntity(existingModel: StorageModel, entity: Entity) -> Update {
        if existingModel.changeDate < entity.changeDate {
            logger?.debug("Updating storage model with entity changes.")
            updateModel(existingModel, entity)
            return .model(existingModel)
        } else {
            logger?.debug("Updating entity with storage model changes.")
            updateEntity(entity, existingModel)
            return .entity(entity)
        }
    }

    static func fetch(from container: ModelContainer) throws -> [Entity] {
        try container.mainContext.fetch(FetchDescriptor<StorageModel>()).compactMap { model in
            Entity(storageModel: model)
        }
    }

    enum Update {
        case model(StorageModel)
        case entity(Entity)
    }

}

// MARK: - Support -

private extension OneStoredSubscriber {

    private func notifySubscriptions() {
        changeSubscriptions.forEach { subsciption in
            subsciption.queue.async(execute: DispatchWorkItem { [weak self] in
                guard let self else { return }
                subsciption.callback(self.entities)
            })
        }
    }

}
