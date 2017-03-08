//
//  Service.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

import Result

/// Default implementation of `Service` protocol.
public class DefaultService: DelegatedService, DataSourcedService {

    public let shadow: ShadowService

    public weak var delegate: ServiceDelegate?
    public weak var dataSource: ServiceDataSource?

    public required init(shadow: ShadowService) {
        self.shadow = shadow
    }
}

public protocol Service: class, ServiceDataSource, ServiceDelegate, CustomStringConvertible {

    /// The service's name.
    ///
    /// - Note:
    ///   Default implementation returns `nil`
    var name: String? { get }

    /// The supporting "shadow" service that does the heavy lifting.
    var shadow: ShadowService { get }

    /// Whether the service should discover characteristics automatically
    ///
    /// - Note:
    ///   Default implementation returns `true`
    var shouldDiscoverCharacteristicsAutomatically: Bool { get }

    /// Initializes a `Service` as a shim for a provided shadow service.
    ///
    /// - Parameters:
    ///   - shadow: The service's "shadow" service
    init(shadow: ShadowService)
}

extension Service {

    /// The Bluetooth-specific identifier of the service.
    public var uuid: Identifier {
        return self.shadow.uuid
    }

    public var name: String? {
        return nil
    }

    public var shouldDiscoverCharacteristicsAutomatically: Bool {
        return false
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

extension Service {

    func characteristic(
        shadow: ShadowCharacteristic,
        forService service: Service
    ) -> Characteristic {
        return DefaultCharacteristic(shadow: shadow)
    }
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
