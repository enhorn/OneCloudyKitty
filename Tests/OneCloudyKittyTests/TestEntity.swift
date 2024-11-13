//
//  SomeEntity.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-11.
//

import Foundation
import CloudKit
import OneCloudyKitty

class TestEntity: OneRecordable {

    enum RecordFields: String {
        case name
        case age
    }

    public var recordID: CKRecord.ID
    public var name: String
    public var age: Int

    init(name: String, age: Int) {
        self.name = name
        self.recordID = Self.generateID()
        self.age = age
    }

    required init?(_ record: CKRecord) {
        guard
            let name = record[RecordFields.name.rawValue] as? String,
            let age = record[RecordFields.age.rawValue] as? Int
        else { return nil }
        self.recordID = record.recordID
        self.name = name
        self.age = age
    }

    func asDictionary() -> [String: Any] {
        [
            RecordFields.name.rawValue: name,
            RecordFields.age.rawValue: age
        ]
    }

}
