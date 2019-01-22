// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public protocol PeripheralProtocol: class {
    var identifier: Identifier { get }

    var name: String? { get }

    var automaticallyDiscoveredServices: [Identifier]? { get }

    var state: PeripheralState { get }

    var services: [Service]? { get }

    var connectionOptions: ConnectionOptions? { get }

    func service<S>(ofType type: S.Type) -> S?
    where S: Service, S: TypeIdentifiable

    func discover(services: [Identifier]?)
    
    func readRSSI()
    
    func updateAdvertisement(_ advertisement: Advertisement)
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
    func didRead(rssi: Result<Float, Error>, of peripheral: Peripheral)
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

@available(iOS 11.0, watchOS 4.0, macOS 10.13, tvOS 11.0, *)
public protocol L2CAPPeripheralProtocol {
    func openL2CAPChannel(_ psm: L2CAPPSM)
}

@available(iOS 11.0, watchOS 4.0, macOS 10.13, tvOS 11.0, *)
public protocol PeripheralL2CAPDelegate: PeripheralDelegate {
    /// This method is the response to a `peripheral.openL2CAPChannel(_:)` call.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral requesting this information.
    ///   - channel: The channel that was opened.
    ///   - error: If an error occurred, the cause of the failure.
    @available(iOS 11.0, watchOS 4.0, macOS 10.13, tvOS 11.0, *)
    func peripheral(_ peripheral: Peripheral, didOpen channel: L2CAPChannel?, error: Error?)
}
