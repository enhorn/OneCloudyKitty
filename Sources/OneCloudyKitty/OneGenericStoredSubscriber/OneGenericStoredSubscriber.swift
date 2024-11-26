//
//  OneGenericStoredSubscriber.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-26.
//

import Foundation

/// Typealias for a generic stored subscriber.
public typealias OneGenericStoredSubscriber = OneStoredSubscriber<OneGenericStorageModel, OneGenericEntity>

extension OneStoredSubscriber {
    
    /// Convenience function to generate a generic ``OneGenericStoredSubscriber`` stored subscriber.
    /// - Parameters:
    ///   - containerURL: URL to the the container sqlite database.
    ///   - controller: ``OneCloudController`` controller to be used.
    ///   - pullInterval: Interval for pulling CloudKit changes. Defaults to `.oneDefaultPullInterval`.
    ///   - debugLogging: If debug logging should be performed. Defaults to `false`.
    /// - Returns: Configured ``OneGenericStoredSubscriber``.
    public static func genericStoredSubscriber(
        containerURL: URL,
        controller: OneCloudController,
        pullInterval: TimeInterval = .oneDefaultPullInterval,
        debugLogging: Bool = false
    ) throws -> OneGenericStoredSubscriber {
        try OneGenericStoredSubscriber(
            containerURL: containerURL,
            controller: controller,
            pullInterval: pullInterval,
            debugLogging: debugLogging,
            updateModel: { model, entity in
                model.data = entity.data
                model.children = entity.children
                model.changeDate = entity.changeDate
            },
            updateEntity: { entity, model in
                entity.data = (try? model.dataOrDecodedStoredData()) ?? [:]
                entity.children = model.childrenOrDecodedStoredChildren()
                entity.changeDate = model.changeDate
            }
        )
    }

}
