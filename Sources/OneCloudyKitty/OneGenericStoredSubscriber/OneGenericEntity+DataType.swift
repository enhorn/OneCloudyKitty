//
//  OneGenericEntity+DataType.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-26.
//

import Foundation

extension OneGenericEntity {

    public enum DataType: Codable, Equatable, CustomStringConvertible {

        case string(String), integer(Int), double(Double), date(Date), bool(Bool), data(Data)

        public var description: String {
            switch self {
                case .string(let string): return string
                case .integer(let int): return String(int)
                case .double(let double): return String(double)
                case .date(let date): return date.description
                case .bool(let bool): return bool.description
                case .data(let data): return data.description
            }
        }

    }

}
