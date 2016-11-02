//
//  Error.swift
//  Blues
//
//  Created by Vincent Esche on 31/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

/// Errors related to a peripheral.
public enum PeripheralError: Swift.Error {
    /// The peripheral is unreachable (e.g. disconnected).
    case unreachable
    /// The action was not handled by the internal responder chain.
    case unhandled
}
