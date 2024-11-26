//
//  OneGenericEntity.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-26.
//

import Foundation
import CloudKit
import SwiftData

// Model fulfilling the protocol `OneRecordable`.
public final class OneGenericEntity: OneRecordableStorable, Equatable, CustomStringConvertible, Identifiable {

    /// `Identifiable` conformance.
    public var id: String { recordID.recordName }

    private(set) var createdDate: Date!

    /// Record identifier.
    public var recordID: CKRecord.ID

    /// Model change dtae.
    public var changeDate: Date

    /// Model data to be stored.
    public var data: [String: DataType] {
        didSet { updateChangeDate(old: oldValue, new: data) }
    }

    /// Model child identifiers.
    public var children: [CKRecord.ID] {
        didSet { updateChangeDate(old: oldValue, new: children) }
    }

    /// - Parameters:
    ///   - recordID: Record ID. Defaults to `OneGenericEntity.generateID()`.
    ///   - createdDate: Creation date. Defaults to `Date.now`.
    ///   - changeDate: Change date. Defaults to `Date.now`.
    ///   - data: Data to store. Defualts to `[:]`.
    ///   - children: Identifiers of children. Default to `[]`.
    public init(
        recordID: CKRecord.ID = OneGenericEntity.generateID(),
        createdDate: Date = Date.now,
        changeDate: Date = Date.now,
        data: [String: DataType] = [:],
        children: [CKRecord.ID] = []
    ) {
        self.recordID = recordID
        self.createdDate = createdDate
        self.changeDate = changeDate
        self.data = data
        self.children = children
    }

    /// Conventience initializer with child entities.
    /// - Parameters:
    ///   - recordID: Record ID. Defaults to `OneGenericEntity.generateID()`.
    ///   - createdDate: Creation date. Defaults to `Date.now`.
    ///   - changeDate: Change date. Defaults to `Date.now`.
    ///   - data: Data to store. Defualts to `[:]`.
    ///   - childEntities: Children to get identifiers from.
    public convenience init(
        recordID: CKRecord.ID = OneGenericEntity.generateID(),
        createdDate: Date = Date.now,
        changeDate: Date = Date.now,
        data: [String: DataType] = [:],
        childEntities: [OneGenericEntity]
    ) {
        self.init(
            recordID: recordID,
            createdDate: createdDate,
            changeDate: changeDate,
            data: data,
            children: childEntities.map { $0.recordID }
        )
    }

    public required init?(_ record: CKRecord) {
        guard let storedData = record["data"] as? Data, let data = try? JSONDecoder().decode([String: DataType].self, from: storedData) else { return nil }

        self.recordID = record.recordID
        self.createdDate = (record["createdDate"] as? Date) ?? Date.now
        self.changeDate = (record["changeDate"] as? Date) ?? Date.now
        self.data = data

        self.children = (record["children"] as? Data).flatMap {
            ((try? JSONDecoder().decode([String].self, from: $0)) ?? []).map(CKRecord.ID.init)
        } ?? []
    }

    public convenience init?(storageModel: any OneRecordableStorageModel) {
        guard let model = storageModel as? OneGenericStorageModel, let data = try? model.dataOrDecodedStoredData() else { return nil }
        self.init(
            recordID: .init(recordName: model.recordID),
            createdDate: model.creationDate,
            changeDate: model.changeDate,
            data: data,
            children: model.childrenOrDecodedStoredChildren()
        )
    }

    public static func == (lhs: OneGenericEntity, rhs: OneGenericEntity) -> Bool {
        return lhs.recordID.recordName == rhs.recordID.recordName
        && lhs.createdDate == rhs.createdDate
        && lhs.changeDate == rhs.changeDate
        && lhs.data == rhs.data
        && lhs.children == rhs.children
    }

}

extension OneGenericEntity {

    // Manual implementation to encode data & children.
    public func asDictionary() -> [String : Any] {
        [
            "changeDate": changeDate,
            "createdDate": createdDate ?? .now,
            "data": (try? JSONEncoder().encode(data)) ?? Data(),
            "children": (try? JSONEncoder().encode(children.map { $0.recordName })) ?? Data()
        ]
    }

    // `OneRecordableStorable` conformance.
    public func storageModel() -> any OneRecordableStorageModel {
        OneGenericStorageModel(
            recordID: recordID.recordName,
            creationDate: createdDate,
            changeDate: changeDate,
            data: data,
            children: children
        )
    }

    // `CustomStringConvertible` conformance.
    public var description: String {
        "OneGenericEntity(data: \(data), children: \(children.map({ $0.recordName })))"
    }

}
