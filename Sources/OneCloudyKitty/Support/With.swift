//
//  With.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-09.
//

import Foundation

protocol With {

    @discardableResult
    func with(_ body: (Self) -> Self) -> Self

    @discardableResult
    func withThrowing(_ body: (Self) throws -> Void) rethrows -> Self

}

extension With {

    @discardableResult
    func withThrowing(_ body: (Self) throws -> Void) rethrows -> Self {
        try body(self)
        return self
    }

    @discardableResult
    func with(_ body: (Self) -> Void) -> Self {
        body(self)
        return self
    }

}

extension NSObjectProtocol {

    @discardableResult
    func with(_ body: (Self) -> Void) -> Self {
        body(self)
        return self
    }

}
