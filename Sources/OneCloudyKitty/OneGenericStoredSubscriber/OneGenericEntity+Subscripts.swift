//
//  OneGenericEntity+Subscripts.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-26.
//

import Foundation

extension OneGenericEntity {

    /// Subscript for fetching a `String` value from the data for the given key.
    /// - Parameter key: Key for the `String` value.
    /// - Returns: The requested `String` if found in the data.
    public subscript(string key: String) -> String? {
        if case .string(let value) = data[key] {
            return value
        } else {
            return nil
        }
    }

    /// Subscript for fetching a `Int` value from the data for the given key.
    /// - Parameter key: Key for the `Int` value.
    /// - Returns: The requested `Int` if found in the data.
    public subscript(integer key: String) -> Int? {
        if case .integer(let value) = data[key] {
            return value
        } else {
            return nil
        }
    }

    /// Subscript for fetching a `Double` value from the data for the given key.
    /// - Parameter key: Key for the `Double` value.
    /// - Returns: The requested `Double` if found in the data.
    public subscript(double key: String) -> Double? {
        if case .double(let value) = data[key] {
            return value
        } else {
            return nil
        }
    }

    /// Subscript for fetching a `Date` value from the data for the given key.
    /// - Parameter key: Key for the `Date` value.
    /// - Returns: The requested `Date` if found in the data.
    public subscript(date key: String) -> Date? {
        if case .date(let value) = data[key] {
            return value
        } else {
            return nil
        }
    }

    /// Subscript for fetching a `Data` value from the data for the given key.
    /// - Parameters:
    ///   - key: Key for the `Data` value.
    ///   - defaultValue: Optional default value. Defaults to `false`.
    /// - Returns: The requested `Data` if found in the data.
    public subscript(bool key: String, defaultValue defaultValue: Bool = false) -> Bool {
        if case .bool(let value) = data[key] {
            return value
        } else {
            return defaultValue
        }
    }

    /// Subscript for fetching a `Data` value from the data for the given key.
    /// - Parameter key: Key for the `Data` value.
    /// - Returns: The requested `Data` if found in the data.
    public subscript(data key: String) -> Data? {
        if case .data(let value) = data[key] {
            return value
        } else {
            return nil
        }
    }

}
