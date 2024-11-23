//
//  OneStoredSubscriber+Subtypes.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-23.
//

import Foundation

extension OneStoredSubscriber {

    /// Closure for updating the model with changes from the entity. Relies on the `changeDate` property of the model & entity.
    public typealias UpdateModel = (_ model: StorageModel, _ entity: Entity) -> Void

    /// Closure for updating the entity with changes from the model. Relies on the `changeDate` property of the model & entity.
    public typealias UpdateEntity = (_ entity: Entity, _ model: StorageModel) -> Void

    /// Stategy for when entities in CloudKit get's deleted.
    public enum DeletionStategy {

        /// Items removed from CloudKit will be kept as-is.
        case ignore

        /// Items removed from CloudKit will be removed from the database.
        case remove

    }

}
