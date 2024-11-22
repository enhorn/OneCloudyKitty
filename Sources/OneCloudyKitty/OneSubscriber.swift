//
//  Subscriber.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-09.
//

import Foundation
import CloudKit

/// Subscriber for a list of entities implementing the ``OneRecordable`` protocol.
@Observable public class OneSubscriber<Entity: OneRecordable> {

    private let notifier = OneNotifier()
    private var listener: OneNotifier.Listener?
    private let pullInterval: TimeInterval
    private var timer: Timer?
    private var changeSubscriptions: [ChangeSubscription] = []

    /// Controller used by the subscriber.
    public let controller: OneCloudController

    /// Current predicate that's applied on fetches.
    /// Refreshes entities list when set.
    public var predicate: NSPredicate {
        didSet {
            Task { [weak self] in
                try? await self?.refresh()
            }
        }
    }

    /// List of fetched entities.
    public private(set) var entities: [Entity] {
        didSet { notifySubscriptions() }
    }

    /// - Parameters:
    ///   - controller: ``OneCloudController`` to use.
    ///   - predicate: Optional predicate to apply to fetches. Defaults to `NSPredicate(value: true)` (all records).
    ///   - initialEntities: Initial entities. Defaults to `[]`.
    ///   - pullInterval: Time interval for automatic pulling of new data. Defaults to `5 minutes`.
    public init(controller: OneCloudController, predicate: NSPredicate = NSPredicate(value: true), initialEntities: [Entity] = [], pullInterval: TimeInterval = 5 * 60) {
        self.controller = controller
        self.predicate = predicate
        self.entities = initialEntities
        self.pullInterval = pullInterval
    }

    deinit {
        stop()
    }

}

// MARK: - API -

public extension OneSubscriber {

    /// Startes the pulling of data. Does nothing if already running.
    func start() {
        guard timer == nil else { return }

        Task { [weak self] in
            try? await self?.refresh()
        }

        timer = Timer.scheduledTimer(withTimeInterval: pullInterval, repeats: true) { [weak self] _ in
            Task { @Sendable [weak self] in
                try? await self?.refresh()
            }
        }

        listener = notifier.register(event: .willEnterForeground) { [weak self] _ in
            Task { @Sendable [weak self] in
                try? await self?.refresh()
            }
        }

        controller.subscribeToChanges { [weak self] in
            Task { @Sendable [weak self] in
                try? await self?.refresh()
            }
        }
    }

    /// Stops the pulling of data.
    func stop() {
        timer?.invalidate()
        timer = nil
        if let listener {
            notifier.deregister(listener: listener)
        }
    }

    /// Manually refreshes the data. Does not the affect the timing of the scheduled pulling of data.
    func refresh() async throws {
        entities = try await controller.getAll(predicate: predicate)
    }
    
    /// Subscribes to changes of the entities with a callback.
    /// - Parameter callback: To be called when entities changes.
    /// - Returns: ``OneSubscriber.ChangeSubscription``. Discardable.
    @discardableResult func subscribeToChanges(callback: @escaping ([Entity]) -> Void) -> ChangeSubscription {
        let subscription = ChangeSubscription(callback: callback)
        subscribeToChanges(subscription: subscription)
        return subscription
    }

    /// Subscribes to changes of the entities.
    /// - Parameter subscription: Subscription object.
    /// - Returns: ``OneSubscriber.ChangeSubscription``. Discardable.
    @discardableResult func subscribeToChanges(subscription: ChangeSubscription) -> ChangeSubscription {
        changeSubscriptions.append(subscription)
        return subscription
    }
    
    /// Unsubscribes from change callbacks.
    /// - Parameter subscription: Subscription to unsubscribe.
    func unsubscribeFromChanges(subscription: ChangeSubscription) {
        changeSubscriptions.removeAll {
            $0.uuid == subscription.uuid
        }
    }

}

extension OneSubscriber {

    /// Subscriber struct for entities changes.
    public struct ChangeSubscription {

        internal let uuid: UUID = UUID()
        internal let queue: DispatchQueue
        internal let callback: ([Entity]) -> Void

        /// - Parameters:
        ///   - queue: Queue to call the callback on.
        ///   - callback: Callback to call on changes.
        public init(queue: DispatchQueue = .main, callback: @escaping ([Entity]) -> Void) {
            self.queue = queue
            self.callback = callback
        }

    }

    private func notifySubscriptions() {
        changeSubscriptions.forEach { subsciption in
            subsciption.queue.async(execute: DispatchWorkItem { [weak self] in
                guard let self else { return }
                subsciption.callback(self.entities)
            })
        }
    }

}

extension OneSubscriber: @unchecked Sendable { }
