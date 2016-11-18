//
//  Error.swift
//  Blues
//
//  Created by Vincent Esche on 31/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

/// Errors related to a descriptor.
public enum TypesafeDescriptorError: Swift.Error {
    /// The descriptor failed to encode its value.
    case encodingFailed(message: String)
    /// The descriptor failed to decode its value.
    case decodingFailed(message: String)
    /// The descriptor does not implement the given transform
    ///
    /// For example a read-only characteristic might choose to not implement the
    /// encoding transform or a write-only the decoding transform respectively.
    case transformNotImplemented
    /// The peripheral encountered an error.
    case peripheral(PeripheralError)
}

/// Errors related to a characteristic.
public enum TypesafeCharacteristicError: Swift.Error {
    /// The characteristic failed to encode its value.
    case encodingFailed(message: String)
    /// The characteristic failed to decode its value.
    case decodingFailed(message: String)
    /// The characteristic does not implement the given transform
    ///
    /// For example a read-only characteristic might choose to not implement the
    /// encoding transform or a write-only the decoding transform respectively.
    case transformNotImplemented
    /// The peripheral encountered an error.
    case peripheral(PeripheralError)
}

/// Errors related to a peripheral.
public enum PeripheralError: Swift.Error {
    /// The peripheral is unreachable (e.g. disconnected).
    case unreachable
    /// The action was not handled by the internal responder chain.
    case unhandled
}
