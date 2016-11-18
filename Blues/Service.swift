//
//  Service.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Default implementation of `Service` protocol.
public class DefaultService: DelegatedService {

    public let shadow: ShadowService

    public weak var delegate: ServiceDelegate?

    public required init(shadow: ShadowService) {
        self.shadow = shadow
    }
}

public protocol Service: class, ServiceDelegate, CustomStringConvertible {

    /// The service's name.
    ///
    /// - Note:
    ///   Default implementation returns `nil`
    var name: String? { get }

    /// The supporting "shadow" service that does the heavy lifting.
    var shadow: ShadowService { get }

    /// Initializes a `Service` as a shim for a provided shadow service.
    ///
    /// - Parameters:
    ///   - shadow: The service's "shadow" service
    init(shadow: ShadowService)

    /// Creates and returns a characteristic for a given shadow characteristic.
    ///
    /// - Note:
    ///   Override this property to provide a custom type for the given characteristic.
    ///   The default implementation creates `DefaultCharacteristic`.
    ///
    /// - Parameters:
    ///   - shadow: The service's shadow characteristic.
    ///
    /// - Returns: A new characteristic object.
    func makeCharacteristic(shadow: ShadowCharacteristic) -> Characteristic
}

extension Service {

    /// The Bluetooth-specific identifier of the service.
    public var uuid: Identifier {
        return self.shadow.uuid
    }

    public var name: String? {
        return nil
    }

    /// `.ok(isPrimary)` with a boolean value indicating whether the type
    /// of service is primary or secondary if successful, otherwise `.err(error)`.
    var isPrimary: Result<Bool, PeripheralError> {
        return self.core.map {
            $0.isPrimary
        }
    }

    /// A list of characteristics that have been discovered in this service.
    ///
    /// - Note:
    ///   This dictionary contains `Characteristic` objects that represent a
    ///   service’s characteristics. Characteristics provide further details
    ///   about a peripheral’s service. For example, a heart rate service may
    ///   contain one characteristic that describes the intended body location
    ///   of the device’s heart rate sensor and another characteristic that
    ///   transmits heart rate measurement data.
    public var characteristics: [Identifier: Characteristic]? {
        return self.shadow.characteristics
    }

    /// The peripheral to which this service belongs.
    public var peripheral: Peripheral? {
        return self.shadow.peripheral
    }

    var core: Result<CBService, PeripheralError> {
        return self.shadow.core.okOr(.unreachable)
    }

    /// Creates and returns a characteristic for a given shadow characteristic.
    ///
    /// - Note:
    ///   Override this property to provide a custom type for the given characteristic.
    ///   The default implementation creates `DefaultCharacteristic`.
    ///
    /// - Parameters:
    ///   - shadow: The characteristic's shadow characteristic.
    ///
    /// - Returns: A new characteristic object.
    public func makeCharacteristic(shadow: ShadowCharacteristic) -> Characteristic {
        return DefaultCharacteristic(shadow: shadow)
    }

    /// Discovers the specified included services of a service.
    ///
    /// - Note:
    ///   You can provide an array of `Identifier` objects—representing
    ///   included service identifiers—in the `includedServices` parameter.
    ///   When you do, the peripheral returns only the included services of the
    ///   service that your app is interested in (recommended).
    ///
    /// - Important:
    ///   If the `includedServicess` parameter is `nil`, all the included services
    ///   of the service are returned; setting the parameter to `nil` is considerably
    ///   slower and is not recommended. When the peripheral discovers one or more
    ///   included services of the specified service, it calls the
    ///   `didDiscover(includedServices:forService:)` method of
    ///   its delegate object. If the included services of a service are successfully
    ///   discovered, you can access them through the service's includedServices property.
    ///
    /// - Parameters:
    ///   - includedServices:
    ///     An array of `Identifier` objects that you are interested in. Here, each
    ///     `Identifier` identifies the type of included service you want to discover.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func discover(includedServices: [Identifier]? = nil) -> Result<(), PeripheralError> {
        return self.shadow.tryToHandle(DiscoverIncludedServicesMessage(
            uuids: includedServices,
            service: self
        )) ?? .err(.unhandled)
    }

    /// Discovers the specified characteristics of a service.
    ///
    /// - Note:
    ///   An array of `Identifier` objects—representing characteristic identifiers—
    ///   can be provided in the `characteristics` parameter. As a result, the
    ///   peripheral returns only the characteristics of the service that your
    ///   app is interested in (recommended). If the `characteristics` parameter
    ///   is `nil`, all the characteristics of the service are returned;
    ///   setting the parameter to `nil` is considerably slower and is not
    ///   recommended. When the peripheral discovers one or more characteristics
    ///   of the specified service, it calls the `didDiscover(characteristics:forService:)`
    ///   method of its delegate object. If the characteristics of a service are
    ///   successfully discovered, you can access them through the service’s
    ///   characteristics property.
    ///
    /// - Parameters:
    ///   - characteristics: An array of `Identifier` objects that you are
    ///     interested in. Here, each `Identifier` object identifies the
    ///     type of a characteristic you want to discover.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func discover(characteristics: [Identifier]?) -> Result<(), PeripheralError> {
        return self.shadow.tryToHandle(DiscoverCharacteristicsMessage(
            uuids: characteristics,
            service: self
        )) ?? .err(.unhandled)
    }
    
    public var description: String {
        let className = type(of: self)
        let attributes = [
            "uuid = \(self.shadow.uuid)",
            "name = \(self.name ?? "<nil>")",
        ].joined(separator: ", ")
        return "<\(className) \(attributes)>"
    }
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
    
    public func didDiscover(includedServices: Result<[Service], Error>, forService service: Service) {
        self.delegate?.didDiscover(includedServices: includedServices, forService: service)
    }
    
    public func didDiscover(characteristics: Result<[Characteristic], Error>, forService service: Service) {
        self.delegate?.didDiscover(characteristics: characteristics, forService: service)
    }
}

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
    func didDiscover(includedServices: Result<[Service], Error>, forService service: Service)

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
    func didDiscover(characteristics: Result<[Characteristic], Error>, forService service: Service)
}

/// The supporting "shadow" service that does the actual heavy lifting
/// behind any `Service` implementation.
public class ShadowService {

    /// The Bluetooth-specific identifier of the service.
    public let uuid: Identifier

    weak var core: CBService?
    weak var peripheral: Peripheral?

    var characteristics: [Identifier: Characteristic]?
    var includedServices: [Identifier: Service]?

    init(core: CBService, peripheral: Peripheral) {
        self.uuid = Identifier(uuid: core.uuid)
        self.core = core
        self.peripheral = peripheral
    }

    func attach(core: CBService) {
        self.core = core
        guard let cores = core.characteristics else {
            return
        }
        for core in cores {
            let uuid = Identifier(uuid: core.uuid)
            guard let characteristic = self.characteristics?[uuid] else {
                continue
            }
            characteristic.shadow.attach(core: core)
        }
    }

    func detach() {
        self.core = nil
        guard let characteristics = self.characteristics?.values else {
            return
        }
        for characteristic in characteristics {
            characteristic.shadow.detach()
        }
    }
}

extension ShadowService: Responder {

    var nextResponder: Responder? {
        return self.peripheral?.shadow
    }
}
