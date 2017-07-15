//
//  PeripheralProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

public protocol PeripheralProtocol: class {
    var identifier: Identifier { get }

    var name: String? { get }

    var automaticallyDiscoveredServices: [Identifier]? { get }

    var state: PeripheralState { get }

    var services: [Service]? { get }

    var connectionOptions: ConnectionOptions? { get }

    init(identifier: Identifier, centralManager: CentralManager)

    func service<S>(ofType type: S.Type) -> S?
    where S: Service, S: TypeIdentifiable

    func discover(services: [Identifier]?)
    
    func readRSSI()
}

public protocol DelegatedPeripheralProtocol: PeripheralProtocol {
    var delegate: PeripheralDelegate? { get set }
}

public protocol DataSourcedPeripheralProtocol: PeripheralProtocol {
    var dataSource: PeripheralDataSource? { get set }
}

/// A `Peripheral`'s delegate.
public protocol PeripheralDelegate: class {}

public protocol PeripheralStateDelegate: PeripheralDelegate {
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
    ///   - rssi: The RSSI, in decibels, of the peripheral, or an error.
    ///   - peripheral: The peripheral providing this information.
    func didRead(rssi: Result<Int, Error>, of peripheral: Peripheral)
}

public protocol PeripheralDiscoveryDelegate: PeripheralDelegate {
    /// Invoked when you discover the peripheral’s available services.
    ///
    /// - Parameters:
    ///   - services: A list of services that have been discovered, or an error.
    ///   - peripheral: The peripheral that the services belong to.
    func didDiscover(services: Result<[Service], Error>, for peripheral: Peripheral)
}

/// A `Peripheral`'s data source.
public protocol PeripheralDataSource: class {
    /// Creates and returns a service for a given identifier.
    ///
    /// - Note:
    ///   Override this property to provide a custom type for the given service.
    ///   The default implementation creates `DefaultService`.
    ///
    /// - Parameters:
    ///   - identifier: The descriptor's identifier.
    ///   - peripheral: The descriptor's peripheral.
    ///
    /// - Returns: A new service object.
    func service(with identifier: Identifier, for peripheral: Peripheral) -> Service
}
