//
//  SomeEntity.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-08.
//

import SwiftUI
import CloudKit
import OneCloudyKitty
import SwiftData

// Model fulfilling the protocol `OneRecordable`.
final class SomeEntity: OneRecordableStorable {

    private(set) var createdDate: Date
    var changeDate: Date

    var recordID: CKRecord.ID

    var name: String {
        didSet { updateChangeDate(old: oldValue, new: name) }
    }

    var age: Int {
        didSet { updateChangeDate(old: oldValue, new: age) }
    }

    init(
        recordID: CKRecord.ID = SomeEntity.generateID(), // Has a defaul implementation in `OneRecordable`.
        name: String,
        age: Int,
        createdDate: Date = Date.now,
        changeDate: Date = Date.now
    ) {
        self.recordID = recordID
        self.name = name
        self.age = age
        self.createdDate = createdDate
        self.changeDate = changeDate
    }

    // Required by `OneRecordableMergable`.
    convenience init?(storageModel: any OneRecordableStorageModel) {
        guard let model = storageModel as? StorageModel else { return nil }
        self.init(recordID: .init(recordName: model.recordID), name: model.name, age: model.age)
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

    func storageModel() -> any OneRecordableStorageModel {
        StorageModel(recordID: recordID.recordName, name: name, age: age, creationDate: createdDate, changeDate: changeDate)
    }

    @Model final class StorageModel: OneRecordableStorageModelMergable {
        var recordID: String!
        var name: String!
        var age: Int!
        var creationDate: Date!
        var changeDate: Date!

        init(recordID: String, name: String, age: Int, creationDate: Date, changeDate: Date) {
            self.recordID = recordID
            self.name = name
            self.age = age
            self.creationDate = creationDate
            self.changeDate = changeDate
        }
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
