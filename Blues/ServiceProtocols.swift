//
//  ServiceProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

public protocol ServiceProtocol: class {
    var identifier: Identifier { get }

    var name: String? { get }

    var peripheral: Peripheral { get }

    var characteristics: [Characteristic]? { get }
    var includedServices: [Service]? { get }

    var automaticallyDiscoveredCharacteristics: [Identifier]? { get }

    var isPrimary: Bool { get }

    init(identifier: Identifier, peripheral: Peripheral)

    func characteristic<C>(ofType type: C.Type) -> C?
    where C: Characteristic, C: TypeIdentifiable

    func discover(includedServices: [Identifier]?)
    func discover(characteristics: [Identifier]?)
}

public protocol DelegatedServiceProtocol: ServiceProtocol {
    var delegate: ServiceDelegate? { get set }
}

public protocol DataSourcedServiceProtocol: ServiceProtocol {
    var dataSource: ServiceDataSource? { get set }
}

/// A `DelegatedService`'s delegate.
public protocol ServiceDelegate: class {
}

public protocol ServiceDiscoveryDelegate: ServiceDelegate {
    /// Invoked when you discover the peripheral’s available services.
    ///
    /// - Note:
    ///   This method is invoked when your app calls the `discover(services:)` method.
    ///
    /// - Parameters:
    ///   - includedServices: `.ok(includedServices)` with the included services that
    ///     were discovered, iff successful, otherwise `.ok(error)`.
    ///   - service: The service that the included services belong to.
    func didDiscover(includedServices: Result<[Service], Error>, for service: Service)

    /// Invoked when you discover the characteristics of a specified service.
    ///
    /// - Note:
    ///   This method is invoked when your app calls the `discover(characteristics:)`
    ///   method. If the characteristics of the specified service are successfully
    ///   discovered, you can access them through the service's characteristics
    ///   property. If successful, the error parameter is nil. If unsuccessful,
    ///   the error parameter returns the cause of the failure.
    ///
    /// - Parameters:
    ///   - characteristics: `.ok(characteristics)` with the characteristics that
    ///     were discovered, iff successful, otherwise `.ok(error)`.
    ///   - service: The service that the characteristics belong to.
    func didDiscover(characteristics: Result<[Characteristic], Error>, for service: Service)
}

/// A `Service`'s data source.
public protocol ServiceDataSource: class {
    /// Creates and returns a characteristic for a given identifier
    ///
    /// - Note:
    ///   Override this property to provide a custom type for the given characteristic.
    ///   The default implementation creates `DefaultCharacteristic`.
    ///
    /// - Parameters:
    ///   - identifier: The characteristic's identifier.
    ///   - service: The characteristic's service.
    ///
    /// - Returns: A new characteristic object.
    func characteristic(with identifier: Identifier, for service: Service) -> Characteristic
}
