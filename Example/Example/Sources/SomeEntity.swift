//
//  SomeEntity.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-08.
//

import SwiftUI
import CloudKit
import OneCloudyKitty

// Model fulfilling the protocol `OneRecordable`.
class SomeEntity: OneRecordable {

    var recordID: CKRecord.ID
    var name: String
    var age: Int

    init(name: String, age: Int) {
        self.recordID = Self.generateID() // Has a defaul implementation in `OneRecordable`.
        self.name = name
        self.age = age
    }

    // From `OneRecordable`
    required init?(_ record: CKRecord) {
        guard let name = record["name"] as? String, let age = record["age"] as? Int else { return nil }
        self.recordID = record.recordID
        self.name = name
        self.age = age
    }

    // From `OneRecordable`
    func asDictionary() -> [String: Any] {
        ["name": name, "age": age]
    }

}

extension SomeEntity {

    var description: String {
        "SomeEntity(name: \"\(name)\", age: \(age))"
    }

}
