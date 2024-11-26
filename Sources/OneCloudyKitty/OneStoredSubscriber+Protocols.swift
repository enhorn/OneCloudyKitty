//
//  OneStoredSubscriber+Protocols.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-23.
//

import Foundation
import SwiftData

/// Persistent storage model protocol.
public typealias OneRecordableStorageModel = OneRecordableStorageModelMergable & PersistentModel

/// Storage model protocol.
public protocol OneRecordableStorageModelMergable {

    /// Record identifier.
    var recordID: String! { get set }

    /// Model change dtae.
    var changeDate: Date! { get set }

}

/// Entity model protocol.
public protocol OneRecordableStorable: OneRecordable {

    /// Model change date.
    var changeDate: Date { get set }

    /// Generates a storage model.
    func storageModel() -> any OneRecordableStorageModel

    /// Initializes with a storage odel.
    init?(storageModel: any OneRecordableStorageModel)

}

extension OneRecordableStorable {
    
    /// Updates the change date property if the values aren't equal.
    /// - Parameters:
    ///   - old: Old value.
    ///   - new: New value.
    public func updateChangeDate<T: Equatable>(old: T, new: T) {
        if old != new {
            changeDate = .now
        }
    }

}
