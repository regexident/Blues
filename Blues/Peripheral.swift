//
//  Peripheral.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

import Result

open class Peripheral: NSObject, PeripheralProtocol {
    /// The Bluetooth-specific identifier of the service.
    public let identifier: Identifier

    /// The peripheral's name.
    ///
    /// - Note:
    ///   Default implementation returns the custom name or if none provided its class name.
    ///
    /// - Important:
    ///   The value of this property is a string containing the device name of the peripheral.
    ///   You can access this property to retrieve a human-readable name of the peripheral.
    ///   There may be two types of names associated with a peripheral:
    ///   one that the device advertises and another that the device publishes in its database
    ///   as its Bluetooth low energy Generic Access Profile (GAP) device name.
    ///   Although this property may contain either type of name,
    ///   the GAP device name takes priority. This means that if a peripheral has both types
    ///   of names associated with it, this property returns its GAP device name.
    ///   Default implementation returns the identifier.
    ///   Override this property to provide a name for your custom type.
    open var name: String? {
        return self.core.name
    }

    /// Which services the peripheral should discover automatically.
    /// Return `nil` to discover all available services.
    ///
    /// - Note:
    ///   Default implementation returns `true`
    open var automaticallyDiscoveredServices: [Identifier]? {
        return nil
    }

    /// The state of the peripheral
    public var state: PeripheralState {
        return PeripheralState(state: self.core.state)
    }

    /// A list of services on the peripheral that have been discovered.
    ///
    /// - Note:
    ///   This dictionary contains `Service` objects that represent a
    ///   peripheral’s services. If you have yet to call the `discover(services:)`
    ///   method to discover the services of the peripheral, or if there was
    ///   an error in doing so, the value of this property is nil.
    public var services: [Service]? {
        return self.servicesByIdentifier.map { Array($0.values) }
    }

    internal var servicesByIdentifier: [Identifier: Service]? = nil

    /// Options customizing the behavior of the connection.
    public var connectionOptions: ConnectionOptions?

    internal var core: CBPeripheral!

    internal var queue: DispatchQueue

    public required init(identifier: Identifier, centralManager: CentralManager) {
        self.identifier = identifier
        self.core = nil
        self.queue = centralManager.queue
    }

    /// The service associated with a given type if it has previously been discovered in this peripheral.
    public func service<S>(ofType type: S.Type) -> S?
        where S: Service,
              S: TypeIdentifiable
    {
        guard let servicesByIdentifier = self.servicesByIdentifier else {
            return nil
        }
        return servicesByIdentifier[type.typeIdentifier] as? S
    }

    /// Discovers the specified services of the peripheral.
    ///
    /// - Note:
    ///   You can provide an array of `Identifier` objects—representing service
    ///   identifiers—in the `services` parameter. When you do, the peripheral
    ///   returns only the services of the peripheral that your app is interested
    ///   in (recommended).
    ///
    /// - Important:
    ///   If the `services` parameter is `nil`, all the available services of
    ///   the peripheral are returned; setting the parameter to `nil` is
    ///   considerably slower and is not recommended. When the peripheral discovers
    ///   one or more services, it calls the `didDiscover(services:for:)`
    ///   method of its delegate object.
    ///
    /// - Parameters:
    ///   - services: An array of `Identifier` objects that you are interested in.
    ///     Here, each `Identifier` identifies the type of service you want to discover.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func discover(services: [Identifier]?) {
        self.core.discoverServices(services?.map { $0.core })
    }

    /// Retrieves the current RSSI value for the peripheral
    /// while it is connected to the central manager.
    ///
    /// - Note:
    ///   In iOS and tvOS, when you call this method to retrieve the RSSI of the
    ///   peripheral while it is currently connected to the central manager,
    ///   the peripheral calls the `didRead(rssi:of:)` method of its
    ///   delegate object, which includes the RSSI value as a parameter.
    public func readRSSI() {
        return self.core.readRSSI()
    }

    internal func isValid(core peripheral: CBPeripheral) -> Bool {
        return peripheral == self.core
    }

    internal func wrapperOf(service: CBService) -> Service? {
        return self.servicesByIdentifier?[Identifier(uuid: service.uuid)]
    }

    internal func wrapperOf(characteristic: CBCharacteristic) -> Characteristic? {
        return self.wrapperOf(service: characteristic.service).flatMap {
            $0.characteristicsByIdentifier?[Identifier(uuid: characteristic.uuid)]
        }
    }

    internal func wrapperOf(descriptor: CBDescriptor) -> Descriptor? {
        return self.wrapperOf(characteristic: descriptor.characteristic).flatMap {
            $0.descriptorsByIdentifier?[Identifier(uuid: descriptor.uuid)]
        }
    }

    internal func wrapper(for core: CBService) -> Service {
        let identifier = Identifier(uuid: core.uuid)
        let service = self.dataSource(from: PeripheralDataSource.self) { dataSource in
            return dataSource.service(with: identifier, for: self)
        } ?? DefaultService(identifier: identifier, peripheral: self)
        service.core = core
        return service
    }

    internal func dataSource<T, U>(from type: T.Type, closure: (T) -> (U)) -> U? {
        if let dataSource = self as? T {
            return closure(dataSource)
        } else if let dataSourcedSelf = self as? DataSourcedPeripheralProtocol {
            if let dataSource = dataSourcedSelf.dataSource as? T {
                return closure(dataSource)
            }
        }
        return nil
    }

    internal func delegate<T, U>(to type: T.Type, closure: (T) -> (U)) -> U? {
        if let delegate = self as? T {
            return closure(delegate)
        } else if let delegatedSelf = self as? DelegatedPeripheralProtocol {
            if let delegate = delegatedSelf.delegate as? T {
                return closure(delegate)
            }
        }
        return nil
    }

    internal func discover(includedServices: [Identifier]?, for service: Service) {
        self.core.discoverIncludedServices(includedServices?.map { $0.core }, for: service.core)
    }

    internal func discover(characteristics: [Identifier]?, for service: Service) {
        self.core.discoverCharacteristics(characteristics?.map { $0.core }, for: service.core)
    }

    internal func discoverDescriptors(for characteristic: Characteristic) {
        self.core.discoverDescriptors(for: characteristic.core)
    }

    internal func readData(for characteristic: Characteristic) {
        self.core.readValue(for: characteristic.core)
    }

    internal func readData(for descriptor: Descriptor) {
        self.core.readValue(for: descriptor.core)
    }

    internal func write(data: Data, for characteristic: Characteristic, type: WriteType) {
        self.core.writeValue(data, for: characteristic.core, type: type.inner)
    }

    internal func write(data: Data, for descriptor: Descriptor) {
        self.core.writeValue(data, for: descriptor.core)
    }

    internal func set(notifyValue: Bool, for characteristic: Characteristic) {
        self.core.setNotifyValue(notifyValue, for: characteristic.core)
    }
}

// MARK: - Equatable
extension Peripheral {
    public static func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

// MARK: - Hashable
extension Peripheral {
    open override var hashValue: Int {
        return self.identifier.hashValue
    }
}

// MARK: - CustomStringConvertible
extension Peripheral {
    override open var description: String {
        let className = String(describing: type(of: self))
        let attributes = [
            "identifier = \(self.identifier)",
            "name = \(self.name ?? "<nil>")",
            "state = \(self.state)",
        ].joined(separator: ", ")
        return "<\(className) \(attributes)>"
    }
}

// MARK: - CBPeripheralDelegate
extension Peripheral: CBPeripheralDelegate {

    public func peripheralDidUpdateName(
        _ peripheral: CBPeripheral
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            self.delegate(to: PeripheralStateDelegate.self) { delegate in
                delegate.didUpdate(name: peripheral.name, of: self)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didModifyServices invalidatedServices: [CBService]
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            let services = invalidatedServices.map { coreService -> Service in
                let identifier = Identifier(uuid: coreService.uuid)
                let service = self.wrapper(for: coreService)
                let characteristics = service.automaticallyDiscoveredCharacteristics
                if let characteristics = characteristics, !characteristics.isEmpty {
                    service.discover(characteristics: characteristics)
                }
                self.servicesByIdentifier?[identifier] = service
                return service
            }
            self.delegate(to: PeripheralStateDelegate.self) { delegate in
                delegate.didModify(services: services, of: self)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didReadRSSI rssi: NSNumber,
        error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            let rssi = (rssi != 0) ? rssi as? Int : nil
            let result = Result(success: rssi, failure: error)
            self.delegate(to: PeripheralStateDelegate.self) { delegate in
                delegate.didRead(rssi: result, of: self)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            let result = Result(success: peripheral.services, failure: error)
            guard case let .ok(coreServices) = result else {
                self.delegate(to: PeripheralDiscoveryDelegate.self) { delegate in
                    delegate.didDiscover(services: .err(error!), for: self)
                }
                return
            }
            var discoveredServices: [Service] = []
            var servicesByIdentifier: [Identifier: Service] = self.servicesByIdentifier ?? [:]
            for coreService in coreServices {
                let identifier = Identifier(uuid: coreService.uuid)
                let service = self.wrapper(for: coreService)
                let characteristics = service.automaticallyDiscoveredCharacteristics
                service.discover(characteristics: characteristics)
                discoveredServices.append(service)
                servicesByIdentifier[identifier] = service
            }
            self.servicesByIdentifier = servicesByIdentifier
            self.delegate(to: PeripheralDiscoveryDelegate.self) { delegate in
                delegate.didDiscover(services: .ok(discoveredServices), for: self)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(service: service) else {
                return
            }
            let result = Result(success: service.includedServices, failure: error)
            guard case let .ok(coreServices) = result else {
                wrapper.delegate(to: ServiceDiscoveryDelegate.self) { delegate in
                    delegate.didDiscover(includedServices: .err(error!), for: wrapper)
                }
                return
            }
            var discoveredServices: [Service] = []
            var services: [Identifier: Service] = wrapper.includedServicesByIdentifier ?? [:]
            for coreService in coreServices {
                let identifier = Identifier(uuid: coreService.uuid)
                let service = self.wrapper(for: coreService)
                let characteristics = service.automaticallyDiscoveredCharacteristics
                service.discover(characteristics: characteristics)
                discoveredServices.append(service)
                services[identifier] = service
            }
            wrapper.includedServicesByIdentifier = services
            wrapper.delegate(to: ServiceDiscoveryDelegate.self) { delegate in
                delegate.didDiscover(includedServices: .ok(discoveredServices), for: wrapper)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(service: service) else {
                return
            }
            let result = Result(success: service.characteristics, failure: error)
            guard case let .ok(coreCharacteristics) = result else {
                wrapper.delegate(to: ServiceDiscoveryDelegate.self) { delegate in
                    delegate.didDiscover(characteristics: .err(error!), for: wrapper)
                }
                return
            }
            var discoveredCharacteristics: [Characteristic] = []
            var characteristicsByIdentifier = wrapper.characteristicsByIdentifier ?? [:]
            for coreCharacteristic in coreCharacteristics {
                let characteristic = wrapper.wrapper(for: coreCharacteristic)
                if characteristic.shouldSubscribeToNotificationsAutomatically {
                    characteristic.set(notifyValue: true)
                }
                if characteristic.shouldDiscoverDescriptorsAutomatically {
                    characteristic.discoverDescriptors()
                }
                discoveredCharacteristics.append(characteristic)
                characteristicsByIdentifier[characteristic.identifier] = characteristic
            }
            wrapper.characteristicsByIdentifier = characteristicsByIdentifier
            wrapper.delegate(to: ServiceDiscoveryDelegate.self) { delegate in
                delegate.didDiscover(characteristics: .ok(discoveredCharacteristics), for: wrapper)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let result = Result(success: characteristic.value, failure: error)
            wrapper.delegate(to: CharacteristicReadingDelegate.self) { delegate in
                delegate.didUpdate(data: result, for: wrapper)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let result = Result(success: characteristic.value, failure: error)
            wrapper.delegate(to: CharacteristicWritingDelegate.self) { delegate in
                delegate.didWrite(data: result, for: wrapper)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let result = Result(success: characteristic.isNotifying, failure: error)
            wrapper.delegate(to: CharacteristicNotificationStateDelegate.self) { delegate in
                delegate.didUpdate(notificationState: result, for: wrapper)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let coreDescriptors = Result(success: characteristic.descriptors, failure: error)
            let descriptors = coreDescriptors.map { coreDescriptors -> [Descriptor] in
                coreDescriptors.map { coreDescriptor in
                    let identifier = Identifier(uuid: coreDescriptor.uuid)
                    let descriptor = wrapper.wrapper(for: coreDescriptor)
                    wrapper.descriptorsByIdentifier?[identifier] = descriptor
                    return descriptor
                }
            }
            wrapper.delegate(to: CharacteristicDiscoveryDelegate.self) { delegate in
                delegate.didDiscover(descriptors: descriptors, for: wrapper)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(descriptor: descriptor) else {
                return
            }
            let result = Result(success: descriptor.value, failure: error)
            wrapper.delegate(to: DescriptorReadingDelegate.self) { delegate in
                delegate.didUpdate(any: result, for: wrapper)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor descriptor: CBDescriptor,
        error: Swift.Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(descriptor: descriptor) else {
                return
            }
            let result = Result(success: descriptor.value, failure: error)
            wrapper.delegate(to: DescriptorWritingDelegate.self) { delegate in
                delegate.didWrite(any: result, for: wrapper)
            }
        }
    }
}
