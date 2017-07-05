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
public protocol CentralManagerDelegate: class {
    /// Invoked when the central manager is about to be restored by the system.
    ///
    /// - Note:
    ///   For apps that opt in to the state preservation and restoration feature
    ///   of Core Bluetooth, this is the first method invoked when your app is
    ///   relaunched into the background to complete some Bluetooth-related task.
    ///   Use this method to synchronize the state of your app with the state
    ///   of the Bluetooth system.
    ///
    /// - Parameters:
    ///   - state: The central manager's restore state.
    ///   - manager: The central manager providing this information.
    func willRestore(state: CentralManagerRestoreState, of manager: CentralManager)

    /// Invoked when the central manager’s state is updated.
    ///
    /// - Parameters:
    ///   - state:   The state of the central manager object.
    ///   - manager: The central manager whose state has changed.
    func didUpdateState(of manager: CentralManager)

    /// Invoked when the central manager discovers a peripheral while scanning.
    ///
    /// - Parameters:
    ///   - peripheral:    The discovered peripheral.
    ///   - rssi:          The rssi value.
    ///   - manager:       The central manager providing the update.
    func didDiscover(peripheral: Peripheral, rssi: Int, with manager: CentralManager)
    
    /// Invoked when the central manager is about to restore a device.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral being restored.
    ///   - manager: The central manager providing this information.
    /// - Returns: The class that is to be instantiated for the given peripheral.
    func didRestore(peripheral: Peripheral, with manager: CentralManager)

    /// Invoked when the central manager retrieves a list of known peripherals.
    ///
    /// - Parameters:
    ///   - peripherals: An array of peripherals currently known by the central manager.
    ///   - manager:     The central manager providing this information.
    func didRetrieve(peripherals: [Peripheral], from manager: CentralManager)

    /// Invoked when the central manager retrieves a list
    /// of peripherals currently connected to the system.
    ///
    /// - Parameters:
    ///   - peripherals: The array of all peripherals currently connected to the system.
    ///   - manager:     The central manager providing this information.
    func didRetrieve(connectedPeripherals: [Peripheral], from manager: CentralManager)
}

/// The `CentralManagerDelegate` protocol defines the methods
/// that a delegate of a `CentralManager` object must adopt.
public protocol CentralManagerDataSource: class {
    /// Invoked when the central manager has discovered a device.
    ///
    /// - Parameters:
    ///   - identifier: The peripheral's identifier.
    ///   - advertisement: The advertisement received during discovery.
    ///   - manager: The central manager providing this information.
    /// - Returns: The class that is to be instantiated for the given peripheral.
    func peripheral(
        with identifier: Identifier,
        advertisement: Advertisement?,
        for manager: CentralManager
    ) -> Peripheral
}
