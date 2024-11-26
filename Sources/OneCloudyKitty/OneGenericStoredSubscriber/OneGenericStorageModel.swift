//
//  OneGenericStorageModel.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-26.
//

import Foundation
import SwiftData
import CloudKit

/// Generic storage model for ``OneGenericEntity``.
@Model public final class OneGenericStorageModel: OneRecordableStorageModelMergable {

    public typealias DataType = OneGenericEntity.DataType

    @Attribute(.unique)
    public var recordID: String!

    var creationDate: Date!
    public var changeDate: Date!
    var storedData: Data!
    var storedChildren: Data!

    @Transient
    var data: [String: DataType]! = [:] {
        didSet { updateStoredData() }
    }

    @Transient
    var children: [CKRecord.ID]! = [] {
        didSet { updateStoredChildren() }
    }

    init(recordID: String, creationDate: Date, changeDate: Date, data: [String: DataType], children: [CKRecord.ID]) {
        self.recordID = recordID
        self.creationDate = creationDate
        self.changeDate = changeDate
        self.data = data
        self.children = children
        if !data.isEmpty { updateStoredData() }
        if !children.isEmpty { updateStoredChildren() }
    }

}

extension OneGenericStorageModel {
    
    /// Retreives the data structure. Parses the stored data represention if needed.
    /// - Returns: The data structure for ``OneGenericEntity``.
    public func dataOrDecodedStoredData() throws -> [String: DataType] {
        if data.isEmpty {
            if storedData == nil {
                self.data = [:]
                return data
            } else {
                let data = try JSONDecoder().decode([String: DataType].self, from: storedData)
                self.data = data
                return data
            }
        } else {
            return data
        }
    }
    
    /// /// Retreives the list of child identifiers. Parses the stored data represention if needed.
    /// - Returns: Array of ``CKRecord.ID``.
    public func childrenOrDecodedStoredChildren() -> [CKRecord.ID] {
        if children.isEmpty {
            let children = storedChildren == nil ? [] : try! JSONDecoder().decode([String].self, from: storedChildren)
            if !children.isEmpty {
                self.children = children.map { CKRecord.ID(recordName: $0) }
            }
            return self.children
        } else {
            return children
        }
    }

    private func updateStoredData() {
        storedData = try! JSONEncoder().encode(data)
    }

    private func updateStoredChildren() {
        storedChildren = try! JSONEncoder().encode(children.map { $0.recordName })
    }

}
