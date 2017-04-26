//
//  ServiceProtocols.swift
//  Blues
//
//  Created by Vincent Esche on 21/11/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// A `DelegatedService`'s delegate.
public protocol ServiceDelegate: class {

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
    func characteristic(shadow: ShadowCharacteristic, for service: Service) -> Characteristic
}

/// A `Service` that supports delegation.
///
/// Note: Conforming to `DelegatedService` adds a default implementation for all
/// functions found in `ServiceDelegate` which simply forwards all method calls
/// to its delegate.
public protocol DelegatedService: Service {

    /// The service's delegate.
    weak var delegate: ServiceDelegate? { get set }
}

extension DelegatedService {

    public func didDiscover(
        includedServices: Result<[Service], Error>,
        for service: Service
    ) {
        self.delegate?.didDiscover(includedServices: includedServices, for: service)
    }

    public func didDiscover(
        characteristics: Result<[Characteristic], Error>,
        for service: Service
    ) {
        self.delegate?.didDiscover(characteristics: characteristics, for: service)
    }
}

/// A `Service` that supports data sourcing.
///
/// Note: Conforming to `DataSourcedService` adds a default implementation for all
/// functions found in `ServiceDataSource` which simply forwards all method calls
/// to its data source.
public protocol DataSourcedService: Service {

    /// The service's delegate.
    weak var dataSource: ServiceDataSource? { get set }
}

extension DataSourcedService {
    public func characteristic(
        shadow: ShadowCharacteristic,
        for service: Service
    ) -> Characteristic {
        if let dataSource = self.dataSource {
            return dataSource.characteristic(shadow: shadow, for: service)
        } else {
            return DefaultCharacteristic(shadow: shadow)
        }
    }
}
