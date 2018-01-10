//
//  MutableDescriptor.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

#if os(iOS) || os(OSX)

open class MutableDescriptor : CBDescriptor {
    internal var core: CBMutableDescriptor

    /// Returns a decriptor, initialized with a service type and value. The _value_ is required
    /// and cannot be updated dynamically once the parent service has been published.
    ///
    /// - Parameters:
    ///   - identifier: The Bluetooth identifier of the descriptor.
    ///   - value: The value of the descriptor.
    public convenience init(type identifier: Identifier, value: Any?) {
        self.init(core: CBMutableDescriptor(
            type: identifier.core,
            value: value
        ))
    }

    public init(core: CBMutableDescriptor) {
        self.core = core
    }
}

#endif
