//
//  PeripheralProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

/// A `DelegatedPeripheral`'s delegate.
public protocol PeripheralDelegate: class {

    /// Invoked when the central manager is about to restore a peripheral's state.
    ///
    /// - parameter peripheral: The peripheral that will be restored.
    func willRestore(peripheral: Peripheral)

    /// Invoked when the central manager has restored a peripheral's state.
    ///
    /// - parameter peripheral: The peripheral that has been restored.
    func didRestore(peripheral: Peripheral)

    /// Invoked when a connection is about to be created with a peripheral.
    ///
    /// - parameter peripheral: The peripheral that will be connected to the system.
    func willConnect(peripheral: Peripheral)

    /// Invoked when a connection is successfully created with a peripheral.
    ///
    /// - parameter peripheral: The peripheral that has been connected to the system.
    func didConnect(peripheral: Peripheral)

    /// Invoked when an existing connection with a peripheral is torn down.
    ///
    /// - parameter peripheral: The peripheral that has been disconnected.
    /// - parameter error:      The cause of the failure.
    func didDisconnect(peripheral: Peripheral, error: Swift.Error?)

    /// Invoked when the central manager fails to create a connection with a peripheral.
    ///
    /// - parameter peripheral: The peripheral that failed to connect.
    /// - parameter error:      The cause of the failure.
    func didFailToConnect(peripheral: Peripheral, error: Swift.Error?)

    func didUpdate(name: String?, ofPeripheral peripheral: Peripheral)
    func didModify(services: [Service], ofPeripheral peripheral: Peripheral)
    func didRead(rssi: Result<Int, Error>, ofPeripheral peripheral: Peripheral)
    func didDiscover(services: Result<[Service], Error>, forPeripheral peripheral: Peripheral)
}

/// A `Peripheral`'s data source.
public protocol PeripheralDataSource: class {
    /// Creates and returns a descriptor for a given shadow descriptor.
    ///
    /// - Note:
    ///   Override this property to provide a custom type for the given descriptor.
    ///   The default implementation creates `DefaultDescriptor`.
    ///
    /// - Parameters:
    ///   - shadow: The descriptor's shadow descriptor.
    ///
    /// - Returns: A new descriptor object.
    func service(shadow: ShadowService, forPeripheral peripheral: Peripheral) -> Service
}

/// A `Peripheral` that supports delegation.
///
/// Note: Conforming to `DelegatedPeripheral` adds a default implementation for all
/// functions found in `PeripheralDelegate` which simply forwards all method calls
/// to its delegate.
public protocol DelegatedPeripheral: Peripheral {

    /// The peripheral's delegate.
    weak var delegate: PeripheralDelegate? { get set }
}

extension DelegatedPeripheral {

    public func willRestore(peripheral: Peripheral) {
        self.delegate?.willRestore(peripheral: peripheral)
    }

    public func didRestore(peripheral: Peripheral) {
        self.delegate?.didRestore(peripheral: peripheral)
    }

    public func willConnect(peripheral: Peripheral) {
        self.delegate?.willConnect(peripheral: peripheral)
    }

    public func didConnect(peripheral: Peripheral) {
        self.delegate?.didConnect(peripheral: peripheral)
    }

    public func didDisconnect(peripheral: Peripheral, error: Swift.Error?) {
        self.delegate?.didDisconnect(peripheral: peripheral, error: error)
    }

    public func didFailToConnect(peripheral: Peripheral, error: Swift.Error?) {
        self.delegate?.didFailToConnect(peripheral: peripheral, error: error)
    }

    public func didUpdate(name: String?, ofPeripheral peripheral: Peripheral) {
        self.delegate?.didUpdate(name: name, ofPeripheral: peripheral)
    }

    public func didModify(services: [Service], ofPeripheral peripheral: Peripheral) {
        self.delegate?.didModify(services: services, ofPeripheral: peripheral)
    }

    public func didRead(rssi: Result<Int, Error>, ofPeripheral peripheral: Peripheral) {
        self.delegate?.didRead(rssi: rssi, ofPeripheral: peripheral)
    }

    public func didDiscover(
        services: Result<[Service], Error>,
        forPeripheral peripheral: Peripheral
    ) {
        self.delegate?.didDiscover(services: services, forPeripheral: peripheral)
    }
}

/// A `Peripheral` that supports delegation.
///
/// Note: Conforming to `DataSourcedPeripheral` adds a default implementation for all
/// functions found in `PeripheralDataSource` which simply forwards all method calls
/// to its data source.
public protocol DataSourcedPeripheral: Peripheral {

    /// The peripheral's delegate.
    weak var dataSource: PeripheralDataSource? { get set }
}

extension DataSourcedPeripheral {
    func service(shadow: ShadowService, forPeripheral peripheral: Peripheral) -> Service {
        return DefaultService(shadow: shadow)
    }
}