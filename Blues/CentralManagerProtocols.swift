//
//  CentralManagerProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

/// The `CentralManagerDelegate` protocol defines the methods
/// that a delegate of a `CentralManager` object must adopt.
public protocol CentralManagerDataSource: class {
    func peripheralClass(forAdvertisement advertisement: Advertisement, onManager manager: CentralManager) -> Peripheral.Type
}

/// The `CentralManagerDelegate` protocol defines the methods
/// that a delegate of a `CentralManager` object must adopt.
public protocol CentralManagerDelegate: class {
    /// Invoked when the central manager’s state is updated.
    ///
    /// - parameter state:   The state of the central manager object.
    /// - parameter manager: The central manager whose state has changed.
    @available(iOSApplicationExtension 10.0, *)
    func didUpdate(state: CentralManagerState, ofManager manager: CentralManager)

    /// Invoked when the central manager discovers a peripheral while scanning.
    ///
    /// - parameter peripheral:    The discovered peripheral.
    /// - parameter advertisement: The advertisement data.
    /// - parameter manager:       The central manager providing the update.
    func didDiscover(peripheral: Peripheral, advertisement: Advertisement, withManager manager: CentralManager)

    /// Invoked when the central manager retrieves a list of known peripherals.
    ///
    /// - parameter peripherals: An array of peripherals currently known by the central manager.
    /// - parameter manager:     The central manager providing this information.
    func didRetrievePeripherals(peripherals: [Peripheral], fromManager manager: CentralManager)

    /// Invoked when the central manager retrieves a list of peripherals currently connected to the system.
    ///
    /// - parameter peripherals: The array of all peripherals currently connected to the system.
    /// - parameter manager:     The central manager providing this information.
    func didRetrieveConnectedPeripherals(peripherals: [Peripheral], fromManager manager: CentralManager)
}
