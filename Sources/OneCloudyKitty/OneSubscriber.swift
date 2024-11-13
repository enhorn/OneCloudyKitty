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
    public private(set) var entities: [Entity] = []

    /// - Parameters:
    ///   - controller: ``OneCloudController`` to use.
    ///   - predicate: Optional predicate to apply to fetches. Defaults to `NSPredicate(value: true)` (all records).
    ///   - pullInterval: Time interval for automatic pulling of new data. Defaults to `5 minutes`.
    public init(controller: OneCloudController, predicate: NSPredicate = NSPredicate(value: true), pullInterval: TimeInterval = 5 * 60) {
        self.controller = controller
        self.predicate = predicate
        self.pullInterval = pullInterval
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
            Task { @MainActor in
                try? await self?.refresh()
            }
        }
        listener = notifier.register(event: .willEnterForeground) { [weak self] _ in
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
        print("Refreshed entities")
    }

}

extension OneSubscriber: @unchecked Sendable { }
