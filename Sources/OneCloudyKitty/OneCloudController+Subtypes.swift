//
//  OneCloudController+Subtypes.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-10.
//

import Foundation

extension OneCloudController {

    /// CloudKit database to be used.
    public enum Database {

        /// Uses the private CloudKit database.
        case `private`

        /// Uses the public CloudKit database.
        case `public`

        /// Uses the shared CloudKit database.
        case shared

    }

    /// Errors that can occurs.
    public enum Error: Swift.Error {

        /// The record could not be created.
        case couldNotCreateRecord(_ cloudKitError: Swift.Error)

        /// The record could not be deleted.
        case couldNotDeleteRecord(_ cloudKitError: Swift.Error)

        /// The record could not be updated.
        case couldNotUpdateRecord

        /// The record could not be saved.
        case couldNotSaveRecord(_ cloudKitError: Swift.Error)

        /// The records could not be saved.
        case couldNotSaveRecords(_ cloudKitError: Swift.Error)

        /// The `OneRecordable` instance could not be initialized from the returned record. Happens on `create`.
        case createdRecordLacksData

        /// The `OneRecordable` instance could not be initialized from the retured record. Happens on `save`.
        case savedRecordLacksData

        /// Records could not be fetched.
        case couldNotFetchRecords(_ cloudKitError: Swift.Error)

        /// Other CloudKit generated error.
        case other(Swift.Error)

    }

}
