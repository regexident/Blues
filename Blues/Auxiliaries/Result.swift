//
//  Result.swift
//  Blues
//
//  Created by Vincent Esche on 27/02/2017.
//  Copyright © 2017 Vincent Esche. All rights reserved.
//

/// Result is a type that represents either success (`ok`) or failure (`err`).
public enum Result<T, E> {
    /// Contains the success value
    case ok(T)
    /// Contains the error value
    case err(E)

    /// Converts from `Result<T, E>` to `Option<T>`
    /// Converts `self` into an `Option<T>`, consuming `self`, and discarding the error, if any.
    public var ok: T? {
        switch self {
        case .ok(let value): return value
        case .err(_): return nil
        }
    }

    /// Converts from `Result<T, E>` to `Option<E>`
    /// Converts `self` into an `Option<E>`, consuming self, and discarding the success value, if any.
    public var err: E? {
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

    /// Maps a `Result<T, E>` to `Result<U, E>` by applying a public function `f` to a contained `ok` value, leaving an `err` value untouched.
    public func map<U>(_ f: (T) -> U) -> Result<U, E> {
        switch self {
        case .ok(let value): return .ok(f(value))
        case .err(let error): return .err(error)
        }
    }

    /// Maps a `Result<T, E>` to `Result<T, F>` by applying a public function `f` to a contained `err` value, leaving an `ok` value untouched.
    public func mapErr<F>(_ f: (E) -> F) -> Result<T, F> {
        switch self {
        case .ok(let value): return .ok(value)
        case .err(let error): return .err(f(error))
        }
    }

    /// Calls `f` if the result is `ok`, otherwise returns the `err` value of self.
    public func flatMap<U>(_ f: (T) -> Result<U, E>) -> Result<U, E> {
        switch self {
        case .ok(let value): return f(value)
        case .err(let error): return .err(error)
        }
    }

    /// Calls `f` if the result is `ok`, otherwise returns the `err` value of self.
    public func flatMapErr<F>(_ f: (E) -> Result<T, F>) -> Result<T, F> {
        switch self {
        case .ok(let value): return .ok(value)
        case .err(let error): return f(error)
        }
    }

    // Construct a `Result` from a Swift `throws` error handling public function.
    public init(_ capturing: () throws -> T) {
        do {
            self = .ok(try capturing())
        } catch let error {
            self = .err(error as! E)
        }
    }

    // Construct a `Result` from a pair of optional value and optional error.
    public init(success: T?, failure: E?) {
        switch (success, failure) {
        case (let value?, nil):
            self = .ok(value)
        case (nil, let error?):
            self = .err(error)
        case _:
            fatalError("Result accepts either `success` or `failure` to be nil, exclusively")
        }
    }

    /// Unwrap and return the wrapped value or fatal error if nil.
    public func expect(_ message: String) -> T {
        switch self {
        case .ok(let v): return v
        case .err(_): fatalError(message.debugDescription)
        }
    }
}

extension Result where E: Swift.Error {
    // Convert the `Result` back to typical Swift `throws` error handling
    public func unwrap() throws -> T {
        switch self {
        case .ok(let v): return v
        case .err(let e): throw e
        }
    }
}

extension Result where T: Equatable, E: Equatable {
    public static func ==(lhs: Result, rhs: Result) -> Bool {
        switch (lhs, rhs) {
        case let (.ok(lhs), .ok(rhs)): return lhs == rhs
        case let (.err(lhs), .err(rhs)): return lhs == rhs
        case _: return false
        }
    }
}

extension Result: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ok(let value): return ".ok(\(value))"
        case .err(let error): return ".err(\(error))"
        }
    }
}

extension Optional {
    /// Unwrap and return the wrapped value or fatal error if nil.
    public func expect(_ message: String) -> Wrapped {
        if let some = self {
            return some
        } else {
            fatalError(message.debugDescription)
        }
    }

    /// Equivalent to the Swift nil-coalescing operator: `self ?? alternative`.
    public func unwrap(or alternative: @autoclosure () -> Wrapped) -> Wrapped {
        if let some = self {
            return some
        } else {
            return alternative()
        }
    }

    /// Equivalent to the Swift nil-coalescing operator `self ?? alternative()`.
    public func unwrap(orElse alternative: () -> Wrapped) -> Wrapped {
        if let some = self {
            return some
        } else {
            return alternative()
        }
    }

    /// Transforms the `Optional<Wrapped>` into a `Result<Wrapped, E>`
    ///
    /// - returns: `.ok(some)` iff self is `.some(some)`, else `.err(error)`.
    public func ok<E>(or error: @autoclosure () -> E) -> Result<Wrapped, E> {
        if let some = self {
            return .ok(some)
        } else {
            return .err(error())
        }
    }

    /// Transforms the `Optional<Wrapped>` into a `Result<Wrapped, E>`
    ///
    /// - returns: `.ok(some)` iff self is `.some(some)`, else `.err(error())`.
    public func ok<E>(orElse error: () -> E) -> Result<Wrapped, E> {
        if let some = self {
            return .ok(some)
        } else {
            return .err(error())
        }
    }
}
