//
//  CentralManager.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

import Result

/// Abstraction layer around `CBCentralManager`.
open class CentralManager: NSObject, CentralManagerProtocol {
    private struct Constants {
        static let queueLabel = "com.nwtnberlin.blues.queue"
    }

    @available(iOS 10.0, *)
    @available(iOSApplicationExtension 10.0, *)
    public var state: ManagerState {
        return ManagerState(from: self.core.state)
    }

    public var isScanning: Bool {
        return self.core.isScanning
    }

    public var peripherals: [Peripheral] {
        return Array(self.peripheralsByIdentifier.values)
    }
    internal var peripheralsByIdentifier: [Identifier: Peripheral] = [:]

    internal var core: CBCentralManager!

    internal let queue = DispatchQueue(label: Constants.queueLabel, attributes: [])
    internal var timer: Timer?

    public required init(
        options: CentralManagerOptions? = nil,
        queue: DispatchQueue = .global()
    ) {
        super.init()
        self.core = CBCentralManager(delegate: self, queue: queue, options: options?.dictionary)
        self.core.delegate = self
    }

    public func startScanningForPeripherals(
        advertisingWithServices services: [Identifier]? = nil,
        options: CentralManagerScanningOptions? = nil,
        timeout: TimeInterval? = nil
    ) {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.queue.async {
            let uuids = services?.map { $0.uuid }
            self.core.scanForPeripherals(withServices: uuids, options: options?.dictionary)
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
            }
            if let timeout = timeout {
                let timer = Timer(
                    timeInterval: timeout,
                    target: self,
                    selector: #selector(CentralManager.didStopScanningAfterTimeout(_:)),
                    userInfo: nil,
                    repeats: false
                )
                self.timer = timer
                RunLoop.main.add(timer, forMode: .commonModes)
            }
            self.delegated(to: CentralManagerDiscoveryDelegate.self) { delegate in
                delegate.didStartScanningForPeripherals(with: self)
            }
        }
    }

    public func stopScanningForPeripherals() {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.queue.async {
            self.core.stopScan()
            if let timer = self.timer {
                timer.invalidate()
            }
            self.timer = nil
            self.delegated(to: CentralManagerDiscoveryDelegate.self) { delegate in
                delegate.didStopScanningForPeripherals(with: self)
            }
        }
    }

    public func retrievePeripherals(withIdentifiers identifiers: [Identifier]) -> [Peripheral] {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        let cbuuids = identifiers.map {
            $0.core.uuidString
        }
        let nsuuids = cbuuids.flatMap { UUID(uuidString: $0) }
        let innerPeripherals = self.core.retrievePeripherals(withIdentifiers: nsuuids)
        let peripheralIdentifiers = innerPeripherals.map { CBUUID(nsuuid: $0.identifier) }
        return self.peripheralsByIdentifier.flatMap { uuid, peripheral in
            peripheralIdentifiers.contains(uuid.core) ? peripheral : nil
        }
    }

    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [Identifier]) -> [Peripheral] {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        let cbuuids = serviceUUIDs.map { $0.core }
        let innerPeripherals = self.core.retrieveConnectedPeripherals(withServices: cbuuids)
        let peripheralIdentifiers = innerPeripherals.map { CBUUID(nsuuid: $0.identifier) }
        return self.peripheralsByIdentifier.flatMap { uuid, peripheral in
            peripheralIdentifiers.contains(uuid.core) ? peripheral : nil
        }
    }

    public func connect(peripheral: Peripheral, options: ConnectionOptions? = nil) {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        if (peripheral.state == .connected) || (peripheral.state == .connecting) {
            return
        }
        self.queue.async {
            self.delegated(to: CentralManagerConnectionDelegate.self) { delegate in
                delegate.willConnect(to: peripheral, on: self)
            }
            peripheral.connectionOptions = options
            self.core.connect(peripheral.core, options: options?.dictionary)
        }
    }

    public func disconnect(peripheral: Peripheral) {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        if (peripheral.state == .disconnected) || (peripheral.state == .disconnecting) {
            return
        }
        self.queue.async {
            self.delegated(to: CentralManagerConnectionDelegate.self) { delegate in
                delegate.willDisconnect(from: peripheral, on: self)
            }
            peripheral.connectionOptions = nil
            self.core.cancelPeripheralConnection(peripheral.core)
        }
    }
    
    public func disconnectAll() {
        assert(self.state == .poweredOn, self.apiMisuseErrorMessage())
        self.queue.async {
            for peripheral in self.peripherals {
                if peripheral.state == .connected {
                    self.disconnect(peripheral: peripheral)
                }
            }
        }
    }

    fileprivate func apiMisuseErrorMessage() -> String {
        return "\(type(of: self)) can only accept commands while in the connected state."
    }

    internal func wrapper(for core: CBPeripheral, advertisement: Advertisement?) -> Peripheral {
        let identifier = Identifier(uuid: core.identifier)
        let peripheral = self.dataSourced(from: CentralManagerDataSource.self) { dataSource in
            return dataSource.peripheral(
                with: identifier,
                advertisement: advertisement,
                for: self
            )
        } ?? DefaultPeripheral(identifier: identifier, centralManager: self)
        peripheral.core = core
        core.delegate = peripheral
        return peripheral
    }

    internal func dataSourced<T, U>(from type: T.Type, closure: (T) -> (U)) -> U? {
        if let dataSource = self as? T {
            return closure(dataSource)
        } else if let dataSourcedSelf = self as? DataSourcedCentralManagerProtocol {
            if let dataSource = dataSourcedSelf.dataSource as? T {
                return closure(dataSource)
            }
        }
        return nil
    }

    internal func delegated<T, U>(to type: T.Type, closure: (T) -> (U)) -> U? {
        if let delegate = self as? T {
            return closure(delegate)
        } else if let delegatedSelf = self as? DelegatedCentralManagerProtocol {
            if let delegate = delegatedSelf.delegate as? T {
                return closure(delegate)
            }
        }
        return nil
    }

    @objc private func didStopScanningAfterTimeout(_ timer: Timer) {
        if self.state == .poweredOn {
            self.stopScanningForPeripherals()
        }
        timer.invalidate()
        self.timer = nil
    }
}

// MARK: - CustomStringConvertible
extension CentralManager {
    override open var description: String {
        let className = String(describing: type(of: self))
        let attributes: String
        if #available(iOS 10.0, *) {
            attributes = [
                "state = \(self.state)",
            ].joined(separator: ", ")
        } else {
            attributes = [
                // nothing yet
            ].joined(separator: ", ")
        }
        return "<\(className) \(attributes)>"
    }
}

// MARK: - CBCentralManagerDelegate:
extension CentralManager: CBCentralManagerDelegate {
    @objc public func centralManager(
        _ central: CBCentralManager,
        willRestoreState dictionary: [String: Any]
    ) {
        self.queue.async {
            let restoreState = CentralManagerRestoreState(dictionary: dictionary) { core in
                let peripheral = self.wrapper(for: core, advertisement: nil)
                self.peripheralsByIdentifier[peripheral.identifier] = peripheral
                return peripheral
            }
            self.delegated(to: CentralManagerRestorationDelegate.self) { delegate in
                delegate.willRestore(state: restoreState, of: self)
            }
            // We discover after calling the delegate to give them
            // a chance to set delegates on the restored peripherals:
            guard self.state == .poweredOn else {
                return
            }
            guard let peripherals = restoreState.peripherals else {
                return
            }
            for peripheral in peripherals {
                let services = peripheral.automaticallyDiscoveredServices
                let shouldDiscoverServices = services.map { !$0.isEmpty } ?? true
                if shouldDiscoverServices {
                    peripheral.discover(services: services)
                }
            }
        }
    }

    @objc public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = ManagerState(from: central.state)
        self.queue.async {
            if central.state == .poweredOn {
                // nothing for now
            } else if central.state == .poweredOff {
                for peripheral in self.peripherals where peripheral.state == .connected {
                    self.delegated(to: CentralManagerConnectionDelegate.self) { delegate in
                        delegate.didDisconnect(from: peripheral, error: nil, on: self)
                    }
                }
            }
            self.delegated(to: CentralManagerStateDelegate.self) { delegate in
                delegate.didUpdateState(of: self)
            }
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        self.queue.async {
            let identifier = Identifier(uuid: peripheral.identifier)
            let existing = self.peripheralsByIdentifier[identifier]
            let wrapper: Peripheral
            if let existingWrapper = existing {
                wrapper = existingWrapper
            } else {
                let advertisement = Advertisement(dictionary: advertisementData)
                wrapper = self.wrapper(for: peripheral, advertisement: advertisement)
                self.peripheralsByIdentifier[wrapper.identifier] = wrapper
            }
            self.delegated(to: CentralManagerDiscoveryDelegate.self) { delegate in
                delegate.didDiscover(peripheral: wrapper, rssi: RSSI as! Int, with: self)
            }
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        self.queue.async {
            let identifier = Identifier(uuid: peripheral.identifier)
            guard let wrapper = self.peripheralsByIdentifier[identifier] else {
                return
            }
            self.delegated(to: CentralManagerConnectionDelegate.self) { delegate in
                delegate.didConnect(to: wrapper, on: self)
            }
            // We discover after calling the delegate to give them
            // a chance to set delegates on the connected peripheral:
            let services = wrapper.automaticallyDiscoveredServices
            let shouldDiscoverServices = services.map { !$0.isEmpty } ?? true
            if shouldDiscoverServices {
                wrapper.discover(services: services)
            }
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Swift.Error?
    ) {
        self.queue.async {
            let identifier = Identifier(uuid: peripheral.identifier)
            guard let wrapper = self.peripheralsByIdentifier[identifier] else {
                return
            }
            self.delegated(to: CentralManagerConnectionDelegate.self) { delegate in
                delegate.didFailToConnect(to: wrapper, error: error, on: self)
            }
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Swift.Error?
    ) {
        self.queue.async {
            let identifier = Identifier(uuid: peripheral.identifier)
            guard let wrapper = self.peripheralsByIdentifier[identifier] else {
                return
            }
            self.delegated(to: CentralManagerConnectionDelegate.self) { delegate in
                delegate.didDisconnect(from: wrapper, error: error, on: self)
            }
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didRetrievePeripherals peripherals: [CBPeripheral]
    ) {
        self.queue.async {
            let peripherals: [Peripheral] = peripherals.flatMap { peripheral in
                let identifier = Identifier(uuid: peripheral.identifier)
                guard let peripheral = self.peripheralsByIdentifier[identifier] else {
                    return nil
                }
                return peripheral
            }
            self.delegated(to: CentralManagerRetrievalDelegate.self) { delegate in
                delegate.didRetrieve(peripherals: peripherals, from: self)
            }
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didRetrieveConnectedPeripherals peripherals: [CBPeripheral]
    ) {
        self.queue.async {
            let peripherals: [Peripheral] = peripherals.flatMap { peripheral in
                let identifier = Identifier(uuid: peripheral.identifier)
                guard let peripheral = self.peripheralsByIdentifier[identifier] else {
                    return nil
                }
                return peripheral
            }
            self.delegated(to: CentralManagerRetrievalDelegate.self) { delegate in
                delegate.didRetrieve(connectedPeripherals: peripherals, from: self)
            }
        }
    }
}
