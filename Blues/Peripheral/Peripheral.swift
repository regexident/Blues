// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

open class Peripheral: NSObject, PeripheralProtocol {
    /// The Bluetooth-specific identifier of the peripheral.
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
    open lazy var name: String? = self.core.name

    /// Which services the peripheral should discover automatically.
    /// Return `nil` to discover all available services.
    ///
    /// - Note:
    ///   Default implementation returns `[]`
    open var automaticallyDiscoveredServices: [Identifier]? {
        return []
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

    internal var core: CBPeripheralProtocol!

    internal var queue: DispatchQueue

    public init(identifier: Identifier, centralManager: CentralManager) {
        self.identifier = identifier
        self.core = nil
        self.queue = centralManager.queue
    }
    
    internal init(core: CBPeripheralProtocol, queue: DispatchQueue) {
        self.identifier = Identifier(uuid: core.identifier)
        self.core = core
        self.queue = queue
    }
    
    open func updateAdvertisement(_ advertisement: Advertisement) {
        
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
        assert(self.state == .connected, self.apiMisuseErrorMessage())
        let shouldDiscoverServices = services.map { !$0.isEmpty } ?? true
        guard shouldDiscoverServices else {
            return
        }
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

    internal func apiMisuseErrorMessage() -> String {
        return "\(type(of: self)) can only accept commands while in the connected state."
    }

    internal func isValid(core peripheral: CBPeripheralProtocol) -> Bool {
        return peripheral.identifier == self.core.identifier
    }

    internal func wrapperOf(service: CBServiceProtocol) -> Service? {
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

    internal func wrapper(for core: CBServiceProtocol) -> Service {
        let identifier = Identifier(uuid: core.uuid)
        let service = self.dataSourced(from: PeripheralDataSource.self) { dataSource in
            return dataSource.service(with: identifier, for: self)
        } ?? DefaultService(identifier: identifier, peripheral: self)
        service.core = core
        return service
    }

    internal func dataSourced<T, U>(from type: T.Type, closure: (T) -> (U)) -> U? {
        if let dataSource = self as? T {
            return closure(dataSource)
        } else if let dataSourcedSelf = self as? DataSourcedPeripheralProtocol {
            if let dataSource = dataSourcedSelf.dataSource as? T {
                return closure(dataSource)
            }
        }
        return nil
    }

    internal func delegated<T, U>(to type: T.Type, closure: (T) -> (U)) -> U? {
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
        assert(self.state == .connected, self.apiMisuseErrorMessage())
        self.core.discoverIncludedServices(includedServices?.map { $0.core }, for: service.core)
    }

    internal func discover(characteristics: [Identifier]?, for service: Service) {
        assert(self.state == .connected, self.apiMisuseErrorMessage())
        self.core.discoverCharacteristics(characteristics?.map { $0.core }, for: service.core)
    }

    internal func discoverDescriptors(for characteristic: Characteristic) {
        assert(self.state == .connected, self.apiMisuseErrorMessage())
        self.core.discoverDescriptors(for: characteristic.core)
    }

    internal func readData(for characteristic: Characteristic) {
        assert(self.state == .connected, self.apiMisuseErrorMessage())
        self.core.readValue(for: characteristic.core)
    }

    internal func readData(for descriptor: Descriptor) {
        assert(self.state == .connected, self.apiMisuseErrorMessage())
        self.core.readValue(for: descriptor.core)
    }

    internal func write(data: Data, for characteristic: Characteristic, type: WriteType) {
        assert(self.state == .connected, self.apiMisuseErrorMessage())
        self.core.writeValue(data, for: characteristic.core, type: type.inner)
    }

    internal func write(data: Data, for descriptor: Descriptor) {
        assert(self.state == .connected, self.apiMisuseErrorMessage())
        self.core.writeValue(data, for: descriptor.core)
    }

    internal func set(notifyValue: Bool, for characteristic: Characteristic) {
        assert(self.state == .connected, self.apiMisuseErrorMessage())
        self.core.setNotifyValue(notifyValue, for: characteristic.core)
    }
}

// MARK: - Equatable
extension Peripheral {
    public static func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Peripheral else {
            return false
        }
        
        return self == other
    }
}

// MARK: - Hashable
extension Peripheral {
    open override var hash: Int {
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
        self.corePeripheralDidUpdateName(peripheral)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didModifyServices invalidatedServices: [CBService]
    ) {
        corePeripheral(peripheral, didModifyServices: invalidatedServices)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didReadRSSI rssi: NSNumber,
        error: Swift.Error?
    ) {
        corePeripheral(peripheral, didReadRSSI: rssi, error: error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Swift.Error?
    ) {
        self.corePeripheral(peripheral, didDiscoverServices: error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: Swift.Error?
    ) {
        corePeripheral(peripheral, didDiscoverIncludedServicesFor: service, error: error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Swift.Error?
    ) {
        corePeripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        corePeripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        corePeripheral(peripheral, didWriteValueFor: characteristic, error: error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        corePeripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        corePeripheral(peripheral, didDiscoverDescriptorsFor: characteristic, error: error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: Swift.Error?
    ) {
        corePeripheral(peripheral, didUpdateValueFor: descriptor, error: error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor descriptor: CBDescriptor,
        error: Swift.Error?
    ) {
        corePeripheral(peripheral, didWriteValueFor: descriptor, error: nil)
    }
}

extension Peripheral: CBPeripheralDelegateProtocol {
    func corePeripheralDidUpdateName(_ peripheral: CBPeripheralProtocol) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            self.delegated(to: PeripheralStateDelegate.self) { delegate in
                delegate.didUpdate(name: peripheral.name, of: self)
            }
        }
    }
    
    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didModifyServices invalidatedServices: [CBServiceProtocol]
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            let services = invalidatedServices.map { coreService -> Service in
                let identifier = Identifier(uuid: coreService.uuid)
                let service = self.wrapper(for: coreService)
                self.servicesByIdentifier?[identifier] = service
                return service
            }
            self.delegated(to: PeripheralStateDelegate.self) { delegate in
                delegate.didModify(services: services, of: self)
            }
            // We discover after calling the delegate to give them
            // a chance to set delegates on the modified servises:
            for service in services {
                let characteristics = service.automaticallyDiscoveredCharacteristics
                let shouldDiscoverCharacteristics = characteristics.map { !$0.isEmpty } ?? true
                if shouldDiscoverCharacteristics {
                    service.discover(characteristics: characteristics)
                }
            }
        }
    }
    
    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didReadRSSI RSSI: NSNumber,
        error: Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }

            let result: Result<Float, Error>
            if let error = error {
                result = Result(success: nil, failure: error)
            } else {
                result = Result(success: RSSI as? Float, failure: nil)
            }
            
            self.delegated(to: PeripheralStateDelegate.self) { delegate in
                delegate.didRead(rssi: result, of: self)
            }
        }
    }

    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didDiscoverServices error: Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            let result = Result(success: peripheral.genericServices, failure: error)
            guard case let .ok(coreServices) = result else {
                self.delegated(to: PeripheralDiscoveryDelegate.self) { delegate in
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
            self.delegated(to: PeripheralDiscoveryDelegate.self) { delegate in
                delegate.didDiscover(services: .ok(discoveredServices), for: self)
            }
        }
    }
    
    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didDiscoverIncludedServicesFor service: CBService,
        error: Error?
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
                wrapper.delegated(to: ServiceDiscoveryDelegate.self) { delegate in
                    delegate.didDiscover(includedServices: .err(error!), for: wrapper)
                }
                return
            }
            var discoveredIncludedServices: [Service] = []
            var includedServicesByIdentifier = wrapper.includedServicesByIdentifier ?? [:]
            for coreService in coreServices {
                let identifier = Identifier(uuid: coreService.uuid)
                let service = self.wrapper(for: coreService)
                if includedServicesByIdentifier[service.identifier] == nil {
                    let characteristics = service.automaticallyDiscoveredCharacteristics
                    service.discover(characteristics: characteristics)
                    discoveredIncludedServices.append(service)
                }
                includedServicesByIdentifier[identifier] = service
            }
            wrapper.includedServicesByIdentifier = includedServicesByIdentifier
            wrapper.delegated(to: ServiceDiscoveryDelegate.self) { delegate in
                delegate.didDiscover(includedServices: .ok(discoveredIncludedServices), for: wrapper)
            }
        }
    }
    
    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
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
                wrapper.delegated(to: ServiceDiscoveryDelegate.self) { delegate in
                    delegate.didDiscover(characteristics: .err(error!), for: wrapper)
                }
                return
            }
            var discoveredCharacteristics: [Characteristic] = []
            var characteristicsByIdentifier = wrapper.characteristicsByIdentifier ?? [:]
            for coreCharacteristic in coreCharacteristics {
                let characteristic = wrapper.wrapper(for: coreCharacteristic)
                if characteristicsByIdentifier[characteristic.identifier] == nil {
                    if let characteristic = characteristic as? ReadableCharacteristicProtocol {
                        if characteristic.shouldSubscribeToNotificationsAutomatically {
                            characteristic.set(notifyValue: true)
                        }
                    }
                    if characteristic.shouldDiscoverDescriptorsAutomatically {
                        characteristic.discoverDescriptors()
                    }
                    discoveredCharacteristics.append(characteristic)
                }
                characteristicsByIdentifier[characteristic.identifier] = characteristic
            }
            wrapper.characteristicsByIdentifier = characteristicsByIdentifier
            wrapper.delegated(to: ServiceDiscoveryDelegate.self) { delegate in
                delegate.didDiscover(characteristics: .ok(discoveredCharacteristics), for: wrapper)
            }
        }
    }
    
    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let result = Result(success: characteristic.value, failure: error)
            wrapper.delegated(to: CharacteristicReadingDelegate.self) { delegate in
                delegate.didUpdate(data: result, for: wrapper)
            }
        }
    }
    
    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let result = Result(success: characteristic.value, failure: error)
            wrapper.delegated(to: CharacteristicWritingDelegate.self) { delegate in
                delegate.didWrite(data: result, for: wrapper)
            }
        }
    }
    
    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let result = Result(success: characteristic.isNotifying, failure: error)
            wrapper.delegated(to: CharacteristicNotificationStateDelegate.self) { delegate in
                delegate.didUpdate(notificationState: result, for: wrapper)
            }
        }
    }
    
    func corePeripheral(_ peripheral: CBPeripheralProtocol,
                        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
                        error: Error?
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
            wrapper.delegated(to: CharacteristicDiscoveryDelegate.self) { delegate in
                delegate.didDiscover(descriptors: descriptors, for: wrapper)
            }
        }
    }
    
    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didUpdateValueFor descriptor: CBDescriptor,
        error: Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(descriptor: descriptor) else {
                return
            }
            let result = Result(success: descriptor.value, failure: error)
            wrapper.delegated(to: DescriptorReadingDelegate.self) { delegate in
                delegate.didUpdate(any: result, for: wrapper)
            }
        }
    }
    
    func corePeripheral(
        _ peripheral: CBPeripheralProtocol,
        didWriteValueFor descriptor: CBDescriptor,
        error: Error?
    ) {
        self.queue.async {
            guard self.isValid(core: peripheral) else {
                fatalError("Method called on wrong peripheral")
            }
            guard let wrapper = self.wrapperOf(descriptor: descriptor) else {
                return
            }
            let result = Result(success: descriptor.value, failure: error)
            wrapper.delegated(to: DescriptorWritingDelegate.self) { delegate in
                delegate.didWrite(any: result, for: wrapper)
            }
        }
    }
}
