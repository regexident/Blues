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

open class Peripheral: NSObject {
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
    public var services: [Identifier: Service]?

    /// Options customizing the behavior of the connection.
    public var connectionOptions: ConnectionOptions?

    public weak var centralManager: CentralManager?

    internal var core: CBPeripheral!

    internal var queue: DispatchQueue {
        guard let centralManager = self.centralManager else {
            fatalError("Invalid use of detached Peripheral")
        }
        return centralManager.queue
    }

    public init(identifier: Identifier, centralManager: CentralManager) {
        self.identifier = identifier
        self.core = nil
        self.centralManager = centralManager
    }

    /// The service associated with a given type if it has previously been discovered in this peripheral.
    public func service<S>(ofType type: S.Type) -> S?
        where S: Service,
              S: TypeIdentifiable
    {
        guard let services = self.services else {
            return nil
        }
        return services[type.typeIdentifier] as? S
    }

    /// Establishes a local connection to a peripheral.
    ///
    /// - Note:
    ///   If a local connection to a peripheral is about to establish it
    ///   calls the `didConnect(peripheral:)` method of its delegate object.
    ///
    ///   If a local connection to a peripheral has been successfully established,
    ///   it calls the `didConnect(peripheral:)` method of its delegate object.
    ///
    ///   If the connection attempt fails, it calls the `didFailToConnect(peripheral:error:)`
    ///   method of its delegate object instead.
    ///
    /// - Important:
    ///   Attempts to connect to a peripheral do not time out.
    ///   To explicitly cancel a pending connection to a peripheral, call the
    ///   `disconnect()` method. The disconnect() method is implicitly called
    ///   when a peripheral is deallocated.
    ///
    /// - Parameters:
    ///   - options: Options customizing the behavior of the connection
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func connect(options: ConnectionOptions? = nil) {
        return self.tryToHandle(ConnectPeripheralMessage(
            peripheral: self,
            options: options
        )) {
            NSLog("\(type(of: ConnectPeripheralMessage.self)) not handled.")
        }
    }

    /// Cancels an active or pending local connection to a peripheral.
    ///
    /// - Note:
    ///   This method is nonblocking, and any Peripheral class commands that are
    ///   still pending to peripheral may or may not complete.
    ///
    /// - Important:
    ///   Because other apps may still have a connection to the peripheral,
    ///   canceling a local connection does not guarantee that the underlying
    ///   physical link is immediately disconnected. From the app’s perspective,
    ///   however, the peripheral is considered disconnected, and it calls the
    ///   `didDisconnect(peripheral:error:)` method of its delegate object.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func disconnect() {
        return self.tryToHandle(DisconnectPeripheralMessage(
            peripheral: self
        )) {
            NSLog("\(type(of: DisconnectPeripheralMessage.self)) not handled.")
        }
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
        return self.tryToHandle(DiscoverServicesMessage(
            uuids: services
        )) {
            NSLog("\(type(of: DiscoverServicesMessage.self)) not handled.")
        }
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

    func isValid(core peripheral: CBPeripheral) -> Bool {
        return peripheral == self.core
    }

    internal func wrapperOf(service: CBService) -> Service? {
        return self.services?[Identifier(uuid: service.uuid)]
    }

    internal func wrapperOf(characteristic: CBCharacteristic) -> Characteristic? {
        return self.wrapperOf(service: characteristic.service).flatMap {
            $0.characteristics?[Identifier(uuid: characteristic.uuid)]
        }
    }

    internal func wrapperOf(descriptor: CBDescriptor) -> Descriptor? {
        return self.wrapperOf(characteristic: descriptor.characteristic).flatMap {
            $0.descriptors?[Identifier(uuid: descriptor.uuid)]
        }
    }

    internal func wrapper(for core: CBService) -> Service {
        let identifier = Identifier(uuid: core.uuid)
        let service: Service
        if let dataSource = self as? PeripheralDataSource {
            service = dataSource.service(with: identifier, for: self)
        } else {
            service = DefaultService(identifier: identifier, peripheral: self)
        }
        service.core = core
        return service
    }

    internal func attach(to core: CBPeripheral) {
        core.delegate = self
        self.core = core
        guard let coreServices = core.services else {
            return
        }
        for coreService in coreServices {
            let identifier = Identifier(uuid: coreService.uuid)
            guard let service = self.services?[identifier] else {
                continue
            }
            service.attach(core: coreService)
        }
    }
}

extension Peripheral /* : CustomStringConvertible */ {
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

extension Peripheral: Responder {
    internal var nextResponder: Responder? {
        return self.centralManager
    }
}

extension Peripheral: CBPeripheralDelegate {

    public func peripheralDidUpdateName(
        _ peripheral: CBPeripheral
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            let delegate = self as? PeripheralDelegate
            delegate?.didUpdate(name: peripheral.name, of: self)
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
            let delegate = self as? PeripheralDelegate
            let services = invalidatedServices.map { coreService -> Service in
                let identifier = Identifier(uuid: coreService.uuid)
                let service = self.wrapper(for: coreService)
                let characteristics = service.automaticallyDiscoveredCharacteristics
                service.discover(characteristics: characteristics)
                self.services?[identifier] = service
                return service
            }
            delegate?.didModify(services: services, of: self)
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
            let delegate = self as? PeripheralDelegate
            let rssi = (rssi != 0) ? rssi as? Int : nil
            let result = Result(success: rssi, failure: error)
            delegate?.didRead(rssi: result, of: self)
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
            let delegate = self as? PeripheralDelegate
            let result = Result(success: peripheral.services, failure: error)
            guard case let .ok(coreServices) = result else {
                delegate?.didDiscover(services: .err(error!), for: self)
                return
            }
            var discoveredServices: [Service] = []
            var services: [Identifier: Service] = self.services ?? [:]
            for coreService in coreServices {
                let identifier = Identifier(uuid: coreService.uuid)
                let service = self.wrapper(for: coreService)
                let characteristics = service.automaticallyDiscoveredCharacteristics
                service.discover(characteristics: characteristics)
                discoveredServices.append(service)
                services[identifier] = service
            }
            self.services = services
            delegate?.didDiscover(services: .ok(discoveredServices), for: self)
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
            let delegate = wrapper as? ServiceDelegate
            let result = Result(success: service.includedServices, failure: error)
            guard case let .ok(coreServices) = result else {
                delegate?.didDiscover(includedServices: .err(error!), for: wrapper)
                return
            }
            var discoveredServices: [Service] = []
            var services: [Identifier: Service] = wrapper.includedServices ?? [:]
            for coreService in coreServices {
                let identifier = Identifier(uuid: coreService.uuid)
                let service = self.wrapper(for: coreService)
                let characteristics = service.automaticallyDiscoveredCharacteristics
                service.discover(characteristics: characteristics)
                discoveredServices.append(service)
                services[identifier] = service
            }
            wrapper.includedServices = services
            delegate?.didDiscover(includedServices: .ok(discoveredServices), for: wrapper)
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
            let delegate = wrapper as? ServiceDelegate
            let result = Result(success: service.characteristics, failure: error)
            guard case let .ok(coreCharacteristics) = result else {
                delegate?.didDiscover(characteristics: .err(error!), for: wrapper)
                return
            }
            var discoveredCharacteristics: [Characteristic] = []
            var characteristics = wrapper.characteristics ?? [:]
            for coreCharacteristic in coreCharacteristics {
                let characteristic = wrapper.wrapper(for: coreCharacteristic)
                if characteristic.shouldSubscribeToNotificationsAutomatically {
                    characteristic.set(notifyValue: true)
                }
                if characteristic.shouldDiscoverDescriptorsAutomatically {
                    characteristic.discoverDescriptors()
                }
                discoveredCharacteristics.append(characteristic)
                characteristics[characteristic.identifier] = characteristic
            }
            wrapper.characteristics = characteristics
            delegate?.didDiscover(
                characteristics: .ok(discoveredCharacteristics),
                for: wrapper
            )
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
            guard let delegate = wrapper as? ReadableCharacteristicDelegate else {
                return
            }
            let result = Result(success: characteristic.value, failure: error)
            delegate.didUpdate(data: result, for: wrapper)
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
            guard let delegate = wrapper as? WritableCharacteristicDelegate else {
                return
            }
            let result = Result(success: characteristic.value, failure: error)
            delegate.didWrite(data: result, for: wrapper)
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
            guard let delegate = wrapper as? NotifyableCharacteristicDelegate else {
                return
            }
            let result = Result(success: characteristic.isNotifying, failure: error)
            delegate.didUpdate(notificationState: result, for: wrapper)
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
            guard let delegate = wrapper as? DescribableCharacteristicDelegate else {
                return
            }
            let coreDescriptors = Result(success: characteristic.descriptors, failure: error)
            let descriptors = coreDescriptors.map { coreDescriptors -> [Descriptor] in
                coreDescriptors.map { coreDescriptor in
                    let identifier = Identifier(uuid: coreDescriptor.uuid)
                    let descriptor: Descriptor
                    if let dataSource = wrapper as? CharacteristicDataSource {
                        descriptor = dataSource.descriptor(with: identifier, for: wrapper)
                    } else {
                        descriptor = DefaultDescriptor(
                            identifier: identifier,
                            characteristic: wrapper
                        )
                    }
                    wrapper.descriptors?[identifier] = descriptor
                    return descriptor
                }
            }
            delegate.didDiscover(descriptors: descriptors, for: wrapper)
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
            guard let delegate = wrapper as? ReadableDescriptorDelegate else {
                return
            }
            let result = Result(success: descriptor.value, failure: error)
            delegate.didUpdate(any: result, for: wrapper)
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
            guard let delegate = wrapper as? WritableDescriptorDelegate else {
                return
            }
            let result = Result(success: descriptor.value, failure: error)
            delegate.didWrite(any: result, for: wrapper)
        }
    }
}
