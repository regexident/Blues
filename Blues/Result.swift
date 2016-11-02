//
//  Result.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

/// Result is a type that represents either success (`ok`) or failure (`err`).
public enum Result<T, E> {

    /// Contains the success value
    case ok(T)

    /// Contains the error value
    case err(E)

    /// Converts from `Result<T, E>` to `Option<T>`
    /// Converts `self` into an `Option<T>`, consuming `self`, and discarding the error, if any.
    public var asOk: T? {
        switch self {
        case .ok(let value): return value
        case .err(_): return nil
        }
    }

    /// Converts from `Result<T, E>` to `Option<E>`
    /// Converts `self` into an `Option<E>`, consuming self, and discarding the success value, if any.
    public var asErr: E? {
        switch self {
        case .ok(_): return nil
        case .err(let error): return error
        }
    }

    /// Returns `true` if the result is `ok`
    public var isOk: Bool {
        switch self {
        case .ok(_): return true
        case .err(_): return false
        }
    }

    /// Returns `true` if the result is `err`
    public var isErr: Bool {
        switch self {
        case .ok(_): return false
        case .err(_): return true
        }
    }

    /// Maps a `Result<T, E>` to `Result<U, E>` by applying a function `f` to a contained `ok` value, leaving an `err` value untouched.
    public func map<U>(f: (T) -> U) -> Result<U, E> {
        switch self {
        case .ok(let value): return .ok(f(value))
        case .err(let error): return .err(error)
        }
    }

    /// Maps a `Result<T, E>` to `Result<T, F>` by applying a function `f` to a contained `err` value, leaving an `ok` value untouched.
    public func mapErr<F>(f: (E) -> F) -> Result<T, F> {
        switch self {
        case .ok(let value): return .ok(value)
        case .err(let error): return .err(f(error))
        }
    }

    /// Calls `f` if the result is `ok`, otherwise returns the `err` value of self.
    public func andThen<U>(f: (T) -> Result<U, E>) -> Result<U, E> {
        switch self {
        case .ok(let value): return f(value)
        case .err(let error): return .err(error)
        }
    }

    /// Calls `f` if the result is `err`, otherwise returns the `ok` value of self.
    public func orElse<F>(f: (E) -> Result<T, F>) -> Result<T, F> {
        switch self {
        case .ok(let value): return .ok(value)
        case .err(let error): return f(error)
        }
    }
}

extension Optional {

    /// Equivalent to the Swift nil-coalescing operator: `self ?? alternative`.
    func unwrapOr(_ alternative: Wrapped) -> Wrapped {
        if let some = self {
            return some
        } else {
            return alternative
        }
    }

    /// Equivalent to the Swift nil-coalescing operator `self ?? alternative()`.
    func unwrapOrElse(_ alternative: () -> Wrapped) -> Wrapped {
        if let some = self {
            return some
        } else {
            return alternative()
        }
    }

    /// Transforms the `Optional<Wrapped>` into a `Result<Wrapped, E>`
    ///
    /// - returns: `.ok(some)` iff self is `.some(some)`, else `.err(error)`.
    func okOr<E>(_ error: E) -> Result<Wrapped, E> {
        if let some = self {
            return .ok(some)
        } else {
            return .err(error)
        }
    }

    /// Transforms the `Optional<Wrapped>` into a `Result<Wrapped, E>`
    ///
    /// - returns: `.ok(some)` iff self is `.some(some)`, else `.err(error())`.
    func okOrElse<E>(_ error: () -> E) -> Result<Wrapped, E> {
        if let some = self {
            return .ok(some)
        } else {
            return .err(error())
        }
    }
}

/*
 extension Result where E: Error {
     // Construct a `Result` from a Swift `throws` error handling function
     public init(_ capturing: () throws -> T) {
         do {
             self = .ok(try capturing())
         } catch let error {
             self = .err(error)
         }
     }

     // Convert the `Result` back to typical Swift `throws` error handling
     public func unwrap() throws -> T {
         switch self {
         case .ok(let v): return v
         case .err(let e): throw e
         }
     }
 }
 */
