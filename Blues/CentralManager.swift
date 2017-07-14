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
    public var state: CentralManagerState {
        return CentralManagerState(from: self.core.state)
    }

    public var isScanning: Bool {
        return self.core.isScanning
    }

    fileprivate(set) public var peripherals: [Identifier: Peripheral] = [:]

    internal var core: CBCentralManager!

    internal let queue = DispatchQueue(label: Constants.queueLabel, attributes: [])
    internal var timer: Timer?

    public required init(
        options: CentralManagerOptions? = nil,
        queue: DispatchQueue = .global()
    ) {
        super.init()
        let core = CBCentralManager(
            delegate: self,
            queue: DispatchQueue.global(qos: .background),
            options: options?.dictionary
        )
        self.core = core
        core.delegate = self
    }

    public func startScanningForPeripherals(
        advertisingWithServices services: [Identifier]? = nil,
        options: CentralManagerScanningOptions? = nil,
        timeout: TimeInterval? = nil
    ) {
        guard !self.core.isScanning else {
            return
        }

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
                    selector: #selector(CentralManager.didReachScanningTimeout(_:)),
                    userInfo: nil,
                    repeats: false
                )
                self.timer = timer
                RunLoop.main.add(timer, forMode: .commonModes)
            }
            if let delegate = self as? CentralManagerDiscoveryDelegate {
                delegate.didStartScanningForPeripherals(with: self)
            }
        }
    }

    public func stopScanningForPeripherals() {
        self.queue.async {
            self.core.stopScan()
            if let timer = self.timer {
                timer.invalidate()
            }
            self.timer = nil
            if let delegate = self as? CentralManagerDiscoveryDelegate {
                delegate.didStopScanningForPeripherals(with: self)
            }
        }
    }

    public func retrievePeripherals(withIdentifiers identifiers: [Identifier]) -> [Peripheral] {
        let cbuuids = identifiers.map {
            $0.core.uuidString
        }
        let nsuuids = cbuuids.flatMap { UUID(uuidString: $0) }
        let innerPeripherals = self.core.retrievePeripherals(withIdentifiers: nsuuids)
        let peripheralIdentifiers = innerPeripherals.map { CBUUID(nsuuid: $0.identifier) }
        return self.peripherals.flatMap { uuid, peripheral in
            peripheralIdentifiers.contains(uuid.core) ? peripheral : nil
        }
    }

    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [Identifier]) -> [Peripheral] {
        let cbuuids = serviceUUIDs.map { $0.core }
        let innerPeripherals = self.core.retrieveConnectedPeripherals(withServices: cbuuids)
        let peripheralIdentifiers = innerPeripherals.map { CBUUID(nsuuid: $0.identifier) }
        return self.peripherals.flatMap { uuid, peripheral in
            peripheralIdentifiers.contains(uuid.core) ? peripheral : nil
        }
    }

    public func connect(peripheral: Peripheral, options: ConnectionOptions? = nil) {
        if (peripheral.state == .connected) || (peripheral.state == .connecting) {
            return
        }
        self.queue.async {
            if let delegate = self as? CentralManagerConnectionDelegate {
                delegate.willConnect(to: peripheral, on: self)
            }
            peripheral.connectionOptions = options
            self.core.connect(peripheral.core, options: options?.dictionary)
        }
        return
    }

    public func disconnect(peripheral: Peripheral) {
        if (peripheral.state == .disconnected) || (peripheral.state == .disconnecting) {
            return
        }
        self.queue.async {
            if let delegate = self as? CentralManagerConnectionDelegate {
                delegate.willDisconnect(from: peripheral, on: self)
            }
            peripheral.connectionOptions = nil
            self.core.cancelPeripheralConnection(peripheral.core)
        }
        return
    }
    
    public func disconnectAll() {
        self.queue.async {
            for peripheral in self.peripherals.values {
                if peripheral.state == .connected {
                    self.disconnect(peripheral: peripheral)
                }
            }
        }
    }

    internal func wrapper(for core: CBPeripheral, advertisement: Advertisement?) -> Peripheral {
        let identifier = Identifier(uuid: core.identifier)
        let peripheral: Peripheral
        if let dataSource = self as? CentralManagerDataSource {
            peripheral = dataSource.peripheral(
                with: identifier,
                advertisement: advertisement,
                for: self
            )
        } else {
            peripheral = DefaultPeripheral(identifier: identifier, centralManager: self)
        }
        peripheral.core = core
        core.delegate = peripheral
        return peripheral
    }

    @objc private func didReachScanningTimeout(_ timer: Timer) {
        self.stopScanningForPeripherals()
        timer.invalidate()
        self.timer = nil
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
                self.peripherals[peripheral.identifier] = peripheral
                let services = peripheral.automaticallyDiscoveredServices
                if let services = services, !services.isEmpty {
                    peripheral.discover(services: services)
                }
                return peripheral
            }
            if let delegate = self as? CentralManagerRestorationDelegate {
                delegate.willRestore(state: restoreState, of: self)
            }
        }
    }

    @objc public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.queue.async {
            if central.state == .poweredOn {
                // nothing for now
            } else if central.state == .poweredOff {
                for peripheral in self.peripherals.values {
                    if peripheral.state == .connected {
                        if let delegate = self as? CentralManagerConnectionDelegate {
                            delegate.didDisconnect(from: peripheral, error: nil, on: self)
                        }
                    }
                }
            }
            if let delegate = self as? CentralManagerStateDelegate {
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
            guard self.peripherals[identifier] == nil else {
                return
            }
            let advertisement = Advertisement(dictionary: advertisementData)
            let wrapper = self.wrapper(for: peripheral, advertisement: advertisement)
            self.peripherals[wrapper.identifier] = wrapper
            if let delegate = self as? CentralManagerDiscoveryDelegate {
                delegate.didDiscover(
                    peripheral: wrapper,
                    rssi: RSSI as! Int,
                    with: self
                )
            }
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        self.queue.async {
            let identifier = Identifier(uuid: peripheral.identifier)
            guard let wrapper = self.peripherals[identifier] else {
                return
            }
            let services = wrapper.automaticallyDiscoveredServices
            if let services = services, !services.isEmpty {
                wrapper.discover(services: services)
            }
            if let delegate = self as? CentralManagerConnectionDelegate {
                delegate.didConnect(to: wrapper, on: self)
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
            guard let wrapper = self.peripherals[identifier] else {
                return
            }
            if let delegate = self as? CentralManagerConnectionDelegate {
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
            guard let wrapper = self.peripherals[identifier] else {
                return
            }
            if let delegate = self as? CentralManagerConnectionDelegate {
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
                guard let peripheral = self.peripherals[identifier] else {
                    return nil
                }
                return peripheral
            }
            if let delegate = self as? CentralManagerRetrievalDelegate {
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
                guard let peripheral = self.peripherals[identifier] else {
                    return nil
                }
                return peripheral
            }
            if let delegate = self as? CentralManagerRetrievalDelegate {
                delegate.didRetrieve(connectedPeripherals: peripherals, from: self)
            }
        }
    }
}
