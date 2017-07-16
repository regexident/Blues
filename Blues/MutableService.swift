//
//  MutableService.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

import Result

/// Used to create a local service or included service, which can be added to the local database
/// via `CBPeripheralManager`. Once a service is published, it is cached and can no longer
/// be changed. This class adds write access to all properties in the `CBService` class.
open class MutableService {
    open var includedServices: [Service]? {
        didSet {
            self.core.includedServices = self.includedServices.map { includedServices in
                includedServices.map { $0.core }
            }
        }
    }

    /// A list of characteristics of a service.
    ///
    /// - Note:
    ///   An array containing `Characteristic` objects that represent a service’s characteristics.
    ///   Characteristics provide further details about a peripheral’s service. For example,
    ///   a heart rate service may contain one characteristic that describes the intended
    ///   body location of the device’s heart rate sensor and another characteristic that
    ///   transmits heart rate measurement data.
    open var characteristics: [Characteristic]? {
        didSet {
            self.core.characteristics = self.characteristics.map { characteristics in
                characteristics.map { $0.core }
            }
        }
    }

    internal var core: CBMutableService

    /// Returns a service, initialized with a service type and UUID.
    ///
    /// - Parameters:
    ///   - identifier: The Bluetooth identifier of the service.
    ///   - isPrimary: The type of the service (primary or secondary).
    public convenience init(type identifier: Identifier, primary isPrimary: Bool) {
        self.init(core: CBMutableService(
            type: identifier.core,
            primary: isPrimary
        ))
    }

    internal init(core: CBMutableService) {
        self.core = core
    }
}
