//
//  Recordable.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-08.
//

import Foundation
import CloudKit

/// Protocol used to entities managed by ``OneCloudController``.
public protocol OneRecordable: Identifiable, AnyObject {

    /// Record type. Defaults to the name of the implementor of the protocol.
    static var recordType: CKRecord.RecordType { get }

    /// Record ID.
    var recordID: CKRecord.ID { get set }

    /// Failable initializer from a CloudKit record.
    /// - Parameter record: CloudKit record.
    init?(_ record: CKRecord)
    
    /// Generates a dictionary representation to be used when updating properties on a ``CKRecord``. See function below.
    /// - Returns: Dictionary representation of the stored properties.
    func asDictionary() -> [String: Any]
    
    /// Generates a record identifier. Has a default implementation.
    /// - Returns: Generated ``CKRecord.ID``.
    static func generateID() -> CKRecord.ID

    /// Generates a new ``CKRecord`` and populates it with the data from `asDictionary()`. Has a default implementation.
    /// - Returns: Generated ``CKRecord``.
    func generateNewRecord() -> CKRecord

    
    /// Updates the ``CKRecord`` with the current state of the properties in `asDictionary()`. Has a default implementation.
    /// - Parameter record: Record to update.
    /// - Returns: Updated ``CKRecord``. Discardable.
    @discardableResult func update(record: CKRecord) -> CKRecord

}

// MARK: - Default implementations -

extension OneRecordable {

    public static var recordType: CKRecord.RecordType { String(describing: Self.self) }

    public static func generateID() -> CKRecord.ID {
        CKRecord.ID(recordName: UUID().uuidString)
    }

    public func generateNewRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        return record.with { update(record: $0) }
    }

    @discardableResult
    public func update(record: CKRecord) -> CKRecord {
        for (key, value) in asDictionary() {
            record.setValue(value, forKey: key)
        }
        return record
    }

}