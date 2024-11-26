//
//  Array+OneGenericEntity.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-26.
//

import Foundation

extension Array where Element == OneGenericEntity {

    /// Convenience function to fetch the (first) parent of an entity from an array of entities.
    /// - Parameter entity: The entity to find the (first) parent of.
    /// - Returns: Optional ``OneGenericEntity``.
    public func parent(for entity: Element) -> Element?  {
        first {
            $0.children.contains(entity.recordID)
        }
    }

    /// Convenience function to fetch the children of an entity from an array of entities.
    /// - Parameter entity: The entity to find the children of.
    /// - Returns: Array of ``OneGenericEntity`` entities.
    public func children(for entity: Element) -> [Element] {
        filter {
            entity.children.contains($0.recordID)
        }
    }

}
