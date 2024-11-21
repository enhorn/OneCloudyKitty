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

    private(set) var createdDate: Date
    private(set) var changeDate: Date

    var recordID: CKRecord.ID

    var name: String {
        didSet { updateChangeDate(old: oldValue, new: name) }
    }

    var age: Int {
        didSet { updateChangeDate(old: oldValue, new: age) }
    }

    init(name: String, age: Int) {
        self.recordID = Self.generateID() // Has a defaul implementation in `OneRecordable`.
        self.name = name
        self.age = age
        self.createdDate = Date.now
        self.changeDate = Date.now
    }

    // Required by `OneRecordable`
    required init?(_ record: CKRecord) {
        guard let name = record["name"] as? String, let age = record["age"] as? Int else { return nil }
        self.recordID = record.recordID
        self.name = name
        self.age = age
        self.createdDate = (record["createdDate"] as? Date) ?? Date.now
        self.changeDate = (record["changeDate"] as? Date) ?? Date.now
    }

}

extension SomeEntity {

    var description: String {
        "SomeEntity(name: \"\(name)\", age: \(age))"
    }

    func updateChangeDate<T: Equatable>(old: T, new: T) {
        if old != new {
            changeDate = .now
        }
    }

}
