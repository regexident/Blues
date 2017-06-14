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

open class Service {
    /// The Bluetooth-specific identifier of the service.
    public let identifier: Identifier

    /// The service's name.
    ///
    /// - Note:
    ///   Default implementation returns the identifier.
    open var name: String? {
        return nil
    }

    /// The peripheral to which this service belongs.
    public weak var peripheral: Peripheral?

    /// A list of characteristics that have been discovered in this service.
    ///
    /// - Note:
    ///   This dictionary contains `Characteristic` objects that represent a
    ///   service’s characteristics. Characteristics provide further details
    ///   about a peripheral’s service. For example, a heart rate service may
    ///   contain one characteristic that describes the intended body location
    ///   of the device’s heart rate sensor and another characteristic that
    ///   transmits heart rate measurement data.
    public var characteristics: [Identifier: Characteristic]?

    /// A list of included services.
    ///
    /// - Note:
    ///   A service of a peripheral may contain a reference to other services
    ///   that are available on the peripheral.
    ///   These other services are the included services of the service.
    public var includedServices: [Identifier: Service]?

    internal var core: Result<CBService, PeripheralError>

    /// Which characteristics the service should discover automatically.
    /// Return `nil` to discover all available characteristics.
    ///
    /// - Note:
    ///   Default implementation returns `true`
    open var automaticallyDiscoveredCharacteristics: [Identifier]? {
        return nil
    }

    /// `.ok(isPrimary)` with a boolean value indicating whether the type
    /// of service is primary or secondary if successful, otherwise `.err(error)`.
    public var isPrimary: Result<Bool, PeripheralError> {
        return self.core.map {
            $0.isPrimary
        }
    }

    public init(identifier: Identifier, peripheral: Peripheral) {
        self.identifier = identifier
        self.core = .err(.unreachable)
        self.peripheral = peripheral
    }

    /// The characteristic associated with a given type if it has previously been discovered in this service.
    public func characteristic<C>(ofType type: C.Type) -> C?
        where C: Characteristic,
              C: TypeIdentifiable
    {
        guard let characteristics = self.characteristics else {
            return nil
        }
        return characteristics[type.typeIdentifier] as? C
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
    ///   `didDiscover(includedServices:for:)` method of
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
        return self.tryToHandle(DiscoverIncludedServicesMessage(
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
    ///   of the specified service, it calls the `didDiscover(characteristics:for:)`
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
        return self.tryToHandle(DiscoverCharacteristicsMessage(
            uuids: characteristics,
            service: self
        )) ?? .err(.unhandled)
    }

    internal func wrapper(for core: CBCharacteristic) -> Characteristic {
        let identifier = Identifier(uuid: core.uuid)
        let characteristic: Characteristic
        if let dataSource = self as? ServiceDataSource {
            characteristic = dataSource.characteristic(with: identifier, for: self)
        } else {
            characteristic = DefaultCharacteristic(identifier: identifier, service: self)
        }
        characteristic.core = .ok(core)
        return characteristic
    }

    internal func attach(core: CBService) {
        self.core = .ok(core)
        guard let cores = core.characteristics else {
            return
        }
        for core in cores {
            let identifier = Identifier(uuid: core.uuid)
            guard let characteristic = self.characteristics?[identifier] else {
                continue
            }
            characteristic.attach(core: core)
        }
    }

    internal func detach() {
        self.core = .err(.unreachable)
        guard let characteristics = self.characteristics?.values else {
            return
        }
        for characteristic in characteristics {
            characteristic.detach()
        }
    }
}

extension Service: CustomStringConvertible {
    open var description: String {
        let className = type(of: self)
        let attributes = [
            "identifier = \(self.identifier)",
            "name = \(self.name ?? "<nil>")",
        ].joined(separator: ", ")
        return "<\(className) \(attributes)>"
    }
}

extension Service: Responder {

    internal var nextResponder: Responder? {
        return self.peripheral
    }
}
