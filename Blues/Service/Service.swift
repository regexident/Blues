// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

open class Service: ServiceProtocol {
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
    ///
    /// - Note:
    ///   This property is made `open` to allow for subclasses
    ///   to override getters to return a specialized peripheral:
    ///   ```
    ///   open var peripheral: CustomPeripheral {
    ///       return super.peripheral as! CustomPeripheral
    ///   }
    ///   ```
    open var peripheral: Peripheral {
        return self._peripheral
    }

    private var _peripheral: Peripheral

    /// A list of characteristics that have been discovered in this service.
    ///
    /// - Note:
    ///   This dictionary contains `Characteristic` objects that represent a
    ///   service’s characteristics. Characteristics provide further details
    ///   about a peripheral’s service. For example, a heart rate service may
    ///   contain one characteristic that describes the intended body location
    ///   of the device’s heart rate sensor and another characteristic that
    ///   transmits heart rate measurement data.
    public var characteristics: [Characteristic]? {
        return self.characteristicsByIdentifier.map { Array($0.values) }
    }

    internal var characteristicsByIdentifier: [Identifier: Characteristic]? = nil

    /// A list of included services.
    ///
    /// - Note:
    ///   A service of a peripheral may contain a reference to other services
    ///   that are available on the peripheral.
    ///   These other services are the included services of the service.
    public var includedServices: [Service]? {
        return self.includedServicesByIdentifier.map { Array($0.values) }
    }

    internal var includedServicesByIdentifier: [Identifier: Service]? = nil

    internal var core: CoreServiceProtocol!

    /// Which characteristics the service should discover automatically.
    /// Return `nil` to discover all available characteristics.
    ///
    /// - Note:
    ///   Default implementation returns `[]`
    open var automaticallyDiscoveredCharacteristics: [Identifier]? {
        return []
    }

    /// `.ok(isPrimary)` with a boolean value indicating whether the type
    /// of service is primary or secondary if successful, otherwise `.err(error)`.
    public var isPrimary: Bool {
        return self.core.isPrimary
    }

    public required init(identifier: Identifier, peripheral: Peripheral) {
        self.identifier = identifier
        self.core = nil
        self._peripheral = peripheral
    }

    /// The characteristic associated with a given type if it has previously been discovered in this service.
    public func characteristic<C>(ofType type: C.Type) -> C?
        where C: Characteristic,
              C: TypeIdentifiable
    {
        guard let characteristicsByIdentifier = self.characteristicsByIdentifier else {
            return nil
        }
        return characteristicsByIdentifier[type.typeIdentifier] as? C
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
    public func discover(includedServices: [Identifier]? = nil) {
        self.peripheral.discover(includedServices: includedServices, for: self)
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
    public func discover(characteristics: [Identifier]?) {
        return self.peripheral.discover(characteristics: characteristics, for: self)
    }

    fileprivate func apiMisuseErrorMessage() -> String {
        return "\(type(of: self)) can only accept commands while in the connected state."
    }

    internal func wrapper(for core: CBCharacteristic) -> Characteristic {
        let identifier = Identifier(uuid: core.uuid)
        let characteristic = self.dataSourced(from: ServiceDataSource.self) { dataSource in
            return dataSource.characteristic(with: identifier, for: self)
        } ?? DefaultCharacteristic(identifier: identifier, service: self)
        characteristic.core = core
        return characteristic
    }

    internal func dataSourced<T, U>(from type: T.Type, closure: (T) -> (U)) -> U? {
        if let dataSource = self as? T {
            return closure(dataSource)
        } else if let dataSourcedSelf = self as? DataSourcedServiceProtocol {
            if let dataSource = dataSourcedSelf.dataSource as? T {
                return closure(dataSource)
            }
        }
        return nil
    }

    internal func delegated<T, U>(to type: T.Type, closure: (T) -> (U)) -> U? {
        if let delegate = self as? T {
            return closure(delegate)
        } else if let delegatedSelf = self as? DelegatedServiceProtocol {
            if let delegate = delegatedSelf.delegate as? T {
                return closure(delegate)
            }
        }
        return nil
    }
}

// MARK: - Equatable
extension Service: Equatable {
    public static func == (lhs: Service, rhs: Service) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

// MARK: - Hashable
extension Service: Hashable {
    public var hashValue: Int {
        return self.identifier.hashValue
    }
}

// MARK: - CustomStringConvertible
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
