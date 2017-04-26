//
//  ShadowPeripheral.swift
//  Blues
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

import Result

/// The supporting "shadow" peripheral that does the actual heavy lifting
/// behind any `Peripheral` implementation.
public class ShadowPeripheral: NSObject {

    /// The Bluetooth-specific identifier of the service.
    public let identifier: Identifier

    /// The Bluetooth-specific identifier of the service.
    public var name: String? {
        return self.core.name
    }

    let core: CBPeripheral
    weak var peripheral: Peripheral?
    var connectionOptions: ConnectionOptions?
    var services: [Identifier: Service]?
    weak var centralManager: CentralManager?

    init(core: CBPeripheral, centralManager: CentralManager) {
        self.identifier = Identifier(uuid: core.identifier)
        self.core = core
        self.centralManager = centralManager
        super.init()
        self.core.delegate = self
    }

    var queue: DispatchQueue {
        guard let centralManager = self.centralManager else {
            fatalError("Invalid use of detached ShadowPeripheral")
        }
        return centralManager.queue
    }

    func inner(for peripheral: Peripheral) -> CBPeripheral {
        guard peripheral === peripheral else {
            fatalError("Attempting to access unknown Peripheral")
        }
        return self.core
    }

    func wrapperOf(peripheral: CBPeripheral) -> Peripheral? {
        return self.peripheral
    }

    func wrapperOf(service: CBService) -> Service? {
        return self.services?[Identifier(uuid: service.uuid)]
    }

    func wrapperOf(characteristic: CBCharacteristic) -> Characteristic? {
        return self.wrapperOf(service: characteristic.service).flatMap {
            $0.characteristics?[Identifier(uuid: characteristic.uuid)]
        }
    }

    func wrapperOf(descriptor: CBDescriptor) -> Descriptor? {
        return self.wrapperOf(characteristic: descriptor.characteristic).flatMap {
            $0.descriptors?[Identifier(uuid: descriptor.uuid)]
        }
    }

    func attach() {
        guard let cores = self.core.services else {
            return
        }
        for core in cores {
            let uuid = Identifier(uuid: core.uuid)
            guard let service = self.services?[uuid] else {
                continue
            }
            service.shadow.attach(core: core)
        }
    }

    func detach() {
        guard let services = self.services?.values else {
            return
        }
        for service in services {
            service.shadow.detach()
        }
    }
}

extension ShadowPeripheral: PeripheralHandling {

    func reachability() -> Result<(), PeripheralError> {
        if self.core.state == .connected {
            return .ok(())
        } else {
            return .err(.unreachable)
        }
    }

    func discover(services: [CBUUID]?) -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.discoverServices(services)
        }
    }

    func discover(
        includedServices: [CBUUID]?,
        for service: CBService
    ) -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.discoverIncludedServices(includedServices, for: service)
        }
    }

    func discover(
        characteristics: [CBUUID]?,
        for service: CBService
    ) -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.discoverCharacteristics(characteristics, for: service)
        }
    }

    func discoverDescriptors(for characteristic: CBCharacteristic) -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.discoverDescriptors(for: characteristic)
        }
    }

    func readData(for characteristic: CBCharacteristic) -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.readValue(for: characteristic)
        }
    }

    func readData(for descriptor: CBDescriptor) -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.readValue(for: descriptor)
        }
    }

    func write(
        data: Data,
        for characteristic: CBCharacteristic,
        type: WriteType
    ) -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.writeValue(data, for: characteristic, type: type.inner)
        }
    }

    func write(data: Data, for descriptor: CBDescriptor) -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.writeValue(data, for: descriptor)
        }
    }

    func set(
        notifyValue: Bool,
        for characteristic: CBCharacteristic
    ) -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.setNotifyValue(notifyValue, for: characteristic)
        }
    }

    func readRSSI() -> Result<(), PeripheralError> {
        return self.reachability().map {
            self.core.readRSSI()
        }
    }
}

extension ShadowPeripheral: CBPeripheralDelegate {

    public func peripheralDidUpdateName(
        _ peripheral: CBPeripheral
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(peripheral: peripheral) else {
                return
            }
            wrapper.didUpdate(name: peripheral.name, of: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didModifyServices invalidatedServices: [CBService]
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(peripheral: peripheral) else {
                return
            }
            let shadowService = invalidatedServices.map {
                ShadowService(core: $0, peripheral: wrapper)
            }
            let services = shadowService.map { shadowService -> Service in
                let service = wrapper.service(shadow: shadowService, for: wrapper)
                let characteristics = service.automaticallyDiscoveredCharacteristics
                if case let .err(error) = service.discover(characteristics: characteristics) {
                    print("Error: \(error)")
                }
                wrapper.shadow.services?[shadowService.identifier] = service
                return service
            }
            wrapper.didModify(services: services, of: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didReadRSSI rssi: NSNumber,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(peripheral: peripheral) else {
                return
            }
            let rssi = (rssi != 0) ? rssi as? Int : nil
            let result = Result(success: rssi, failure: error)
            wrapper.didRead(rssi: result, of: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(peripheral: peripheral) else {
                return
            }
            let result = Result(success: peripheral.services, failure: error)
            guard case let .ok(coreServices) = result else {
                return wrapper.didDiscover(services: .err(error!), for: wrapper)
            }
            var discoveredServices: [Service] = []
            var services: [Identifier: Service] = wrapper.shadow.services ?? [:]
            for coreService in coreServices {
                let shadowService = ShadowService(core: coreService, peripheral: wrapper)
                let service = wrapper.service(shadow: shadowService, for: wrapper)
                let characteristics = service.automaticallyDiscoveredCharacteristics
                if case let .err(error) = service.discover(characteristics: characteristics) {
                    print("Error: \(error)")
                }
                discoveredServices.append(service)
                services[service.identifier] = service
            }
            wrapper.shadow.services = services
            wrapper.didDiscover(services: .ok(discoveredServices), for: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let peripheral = self.peripheral else {
                return
            }
            guard let wrapper = self.wrapperOf(service: service) else {
                return
            }
            let result = Result(success: service.includedServices, failure: error)
            guard case let .ok(coreServices) = result else {
                return wrapper.didDiscover(includedServices: .err(error!), for: wrapper)
            }
            var discoveredServices: [Service] = []
            var services: [Identifier: Service] = wrapper.shadow.includedServices ?? [:]
            for coreService in coreServices {
                let shadowService = ShadowService(core: coreService, peripheral: peripheral)
                let service = peripheral.service(shadow: shadowService, for: peripheral)
                let characteristics = service.automaticallyDiscoveredCharacteristics
                if case let .err(error) = service.discover(characteristics: characteristics) {
                    print("Error: \(error)")
                }
                discoveredServices.append(service)
                services[service.identifier] = service
            }
            wrapper.shadow.includedServices = services
            wrapper.didDiscover(includedServices: .ok(discoveredServices), for: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(service: service) else {
                return
            }
            let result = Result(success: service.characteristics, failure: error)
            guard case let .ok(coreCharacteristics) = result else {
                return wrapper.didDiscover(characteristics: .err(error!), for: wrapper)
            }
            var discoveredCharacteristics: [Characteristic] = []
            var characteristics = wrapper.shadow.characteristics ?? [:]
            for coreCharacteristic in coreCharacteristics {
                let shadowCharacteristic = ShadowCharacteristic(
                    core: coreCharacteristic,
                    service: wrapper
                )
                let characteristic = wrapper.characteristic(
                    shadow: shadowCharacteristic,
                    for: wrapper
                )
                if characteristic.shouldSubscribeToNotificationsAutomatically {
                    if case let .err(error) = characteristic.set(notifyValue: true) {
                        print("Error: \(error)")
                    }
                }
                if characteristic.shouldDiscoverDescriptorsAutomatically {
                    if case let .err(error) = characteristic.discoverDescriptors() {
                        print("Error: \(error)")
                    }
                }
                discoveredCharacteristics.append(characteristic)
                characteristics[characteristic.identifier] = characteristic
            }
            wrapper.shadow.characteristics = characteristics
            wrapper.didDiscover(
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
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let result = Result(success: characteristic.value, failure: error)
            wrapper.didUpdate(data: result, for: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let result = Result(success: characteristic.value, failure: error)
            wrapper.didWrite(data: result, for: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let result = Result(success: characteristic.isNotifying, failure: error)
            wrapper.didUpdate(notificationState: result, for: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(characteristic: characteristic) else {
                return
            }
            let coreDescriptors = Result(success: characteristic.descriptors, failure: error)
            let shadowDescriptors = coreDescriptors.map { coreDescriptors in
                coreDescriptors.map {
                    ShadowDescriptor(core: $0, characteristic: wrapper)
                }
            }
            let descriptors = shadowDescriptors.map { shadowDescriptors -> [Descriptor] in
                shadowDescriptors.map { shadowDescriptor in
                    let descriptor = wrapper.descriptor(
                        shadow: shadowDescriptor,
                        for: wrapper
                    )
                    wrapper.shadow.descriptors[shadowDescriptor.identifier] = descriptor
                    return descriptor
                }
            }
            wrapper.didDiscover(descriptors: descriptors, for: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(descriptor: descriptor) else {
                return
            }
            let result = Result(success: descriptor.value, failure: error)
            wrapper.didUpdate(any: result, for: wrapper)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor descriptor: CBDescriptor,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            guard let wrapper = self.wrapperOf(descriptor: descriptor) else {
                return
            }
            let result = Result(success: descriptor.value, failure: error)
            wrapper.didWrite(any: result, for: wrapper)
        }
    }
}

extension ShadowPeripheral: Responder {
    var nextResponder: Responder? {
        guard let centralManager = self.centralManager else {
            fatalError("Expected object conforming to `Responder` protocol.")
        }
        return .some(centralManager)
    }
}
