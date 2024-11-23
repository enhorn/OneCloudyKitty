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
    var recordID: String! { get set }
    var changeDate: Date! { get set }
}

/// Entity model protocol.
public protocol OneRecordableStorable: OneRecordable {
    var changeDate: Date { get set }
    func storageModel() -> any OneRecordableStorageModel
    init?(storageModel: any OneRecordableStorageModel)
}
