//
//  OneChangeSubscription.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-23.
//

import Foundation

/// Subscriber struct for entities changes.
public class OneChangeSubscription<Entity: OneRecordable> {

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
