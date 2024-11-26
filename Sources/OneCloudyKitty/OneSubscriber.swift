//
//  Subscriber.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-09.
//

import Foundation
import CloudKit
import OSLog

/// Subscriber for a list of entities implementing the ``OneRecordable`` protocol.
@MainActor @Observable final public class OneSubscriber<Entity: OneRecordable> {

    private let logger: Logger?
    private let notifier = OneNotifier()
    private var listener: OneNotifier.Listener?
    private let pullInterval: TimeInterval
    private var timer: Timer?
    private var changeSubscriptions: [OneChangeSubscription<Entity>] = []

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
    ///   - pullInterval: Time interval for automatic pulling of new data. Defaults to `.oneDefaultPullInterval`.
    ///   - debugLogging: If debug logging should be performed. Defaults to `false`.
    public init(
        controller: OneCloudController,
        predicate: NSPredicate = NSPredicate(value: true),
        initialEntities: [Entity] = [],
        pullInterval: TimeInterval = .oneDefaultPullInterval,
        debugLogging: Bool = false
    ) {
        self.controller = controller
        self.predicate = predicate
        self.entities = initialEntities
        self.pullInterval = pullInterval
        self.logger = debugLogging ? Logger(subsystem: "com.enhorn.OneCloudyKitty", category: String(describing: Self.self)) : nil
    }

    deinit {
        Task { @MainActor [weak self] in
            self?.stop()
        }
    }

}

// MARK: - API -

public extension OneSubscriber {

    /// Startes the pulling of data. Does nothing if already running.
    func start() {
        guard timer == nil else { return }
        logger?.debug("Starting subscription.")

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
        logger?.debug("Stopping subscription.")
        timer?.invalidate()
        timer = nil
        if let listener {
            notifier.deregister(listener: listener)
        }
    }

    /// Manually refreshes the data. Does not the affect the timing of the scheduled pulling of data.
    func refresh() async throws {
        do {
            entities = try await controller.getAll(predicate: predicate)
            logger?.debug("Refreshed entities.")
        } catch let error {
            logger?.error("Failed to refresh entities: \(error)")
            throw error
        }
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

extension OneSubscriber {

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
