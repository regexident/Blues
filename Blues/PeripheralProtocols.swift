//
//  PeripheralProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// A `DelegatedPeripheral`'s delegate.
public protocol PeripheralDelegate: class {

    /// Invoked when a connection is about to be created with a peripheral.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral that will be connected to the system.
    func willConnect(to peripheral: Peripheral)

    /// Invoked when a connection is successfully created with a peripheral.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral that has been connected to the system.
    func didConnect(to peripheral: Peripheral)

    /// Invoked when a connection is about to be created with a peripheral.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral that will be connected to the system.
    func willDisconnect(from peripheral: Peripheral)

    /// Invoked when an existing connection with a peripheral is torn down.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral that has been disconnected.
    ///   - error:      The cause of the failure.
    func didDisconnect(from peripheral: Peripheral, error: Swift.Error?)

    /// Invoked when the central manager fails to create a connection with a peripheral.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral that failed to connect.
    ///   - error:      The cause of the failure.
    func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?)

    /// Invoked when a peripheral’s name changes.
    ///
    /// - Parameters:
    ///   - name: The peripheral's new name.
    ///   - peripheral: The peripheral providing this information.
    func didUpdate(name: String?, of peripheral: Peripheral)

    /// Invoked when a peripheral’s services have changed.
    ///
    /// - Parameters:
    ///   - services: A list of services that have been invalidated.
    ///   - peripheral: The peripheral providing this information.
    func didModify(services: [Service], of peripheral: Peripheral)

    /// Invoked after you call readRSSI() to retrieve the value of the peripheral’s
    /// current RSSI while it is connected to the central manager.
    ///
    /// - Parameters:
    ///   - rssi: The RSSI, in decibels, of the peripheral.
    ///   - peripheral: The peripheral providing this information.
    func didRead(rssi: Result<Int, Error>, of peripheral: Peripheral)
    func didDiscover(services: Result<[Service], Error>, for peripheral: Peripheral)
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
    func service(shadow: ShadowService, for peripheral: Peripheral) -> Service
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

    public func willConnect(to peripheral: Peripheral) {
        self.delegate?.willConnect(to: peripheral)
    }

    public func didConnect(to peripheral: Peripheral) {
        self.delegate?.didConnect(to: peripheral)
    }

    public func willDisconnect(from peripheral: Peripheral) {
        self.delegate?.willDisconnect(from: peripheral)
    }

    public func didDisconnect(from peripheral: Peripheral, error: Swift.Error?) {
        self.delegate?.didDisconnect(from: peripheral, error: error)
    }

    public func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?) {
        self.delegate?.didFailToConnect(to: peripheral, error: error)
    }

    public func didUpdate(name: String?, of peripheral: Peripheral) {
        self.delegate?.didUpdate(name: name, of: peripheral)
    }

    public func didModify(services: [Service], of peripheral: Peripheral) {
        self.delegate?.didModify(services: services, of: peripheral)
    }

    public func didRead(rssi: Result<Int, Error>, of peripheral: Peripheral) {
        self.delegate?.didRead(rssi: rssi, of: peripheral)
    }

    public func didDiscover(
        services: Result<[Service], Error>,
        for peripheral: Peripheral
    ) {
        self.delegate?.didDiscover(services: services, for: peripheral)
    }
}

/// A `Peripheral` that supports data sourcing.
///
/// Note: Conforming to `DataSourcedPeripheral` adds a default implementation for all
/// functions found in `PeripheralDataSource` which simply forwards all method calls
/// to its data source.
public protocol DataSourcedPeripheral: Peripheral {

    /// The peripheral's delegate.
    weak var dataSource: PeripheralDataSource? { get set }
}

extension DataSourcedPeripheral {
    public func service(shadow: ShadowService, for peripheral: Peripheral) -> Service {
        if let dataSource = self.dataSource {
            return dataSource.service(shadow: shadow, for: peripheral)
        } else {
            return DefaultService(shadow: shadow)
        }
    }
}
