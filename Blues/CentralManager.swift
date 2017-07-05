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
open class CentralManager: NSObject {
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

    fileprivate(set) public weak var dataSource: CentralManagerDataSource?
    fileprivate(set) public weak var delegate: CentralManagerDelegate?

    internal var core: CBCentralManager!

    internal let queue = DispatchQueue(label: Constants.queueLabel, attributes: [])

    public init(
        delegate: CentralManagerDelegate? = nil,
        dataSource: CentralManagerDataSource? = nil,
        options: CentralManagerOptions? = nil
    ) {
        self.delegate = delegate
        self.dataSource = dataSource
        super.init()
        self.core = CBCentralManager(
            delegate: self,
            queue: DispatchQueue.main, // global(qos: .background),
            options: options?.dictionary
        )
    }

    public func startScanningForPeripherals(
        advertisingWithServices services: [String]? = nil,
        options: CentralManagerScanningOptions? = nil
    ) {
        guard !self.core.isScanning else {
            return
        }

        self.queue.async {
            let uuids = services?.map { CBUUID(string: $0) }
            self.core.scanForPeripherals(withServices: uuids, options: options?.dictionary)
        }
    }

    public func stopScanningForPeripherals() {
        self.queue.async {
            self.core.stopScan()
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
        peripheral.attach(to: core)
        return peripheral
    }
}

// MARK: - CentralManagerHandling:
extension CentralManager: CentralManagerHandling {
    func connect(
        peripheral: Peripheral,
        options: ConnectionOptions? = nil
    ) {
        if (peripheral.state == .connected) || (peripheral.state == .connecting) {
            return
        }
        self.queue.async {
            let delegate = peripheral as? PeripheralDelegate
            delegate?.willConnect(to: peripheral)
            peripheral.connectionOptions = options
            self.core.connect(peripheral.core, options: options?.dictionary)
        }
        return
    }

    func disconnect(peripheral: Peripheral) {
        if (peripheral.state == .disconnected) || (peripheral.state == .disconnecting) {
            return
        }
        self.queue.async {
            let delegate = peripheral as? PeripheralDelegate
            delegate?.willDisconnect(from: peripheral)
            peripheral.connectionOptions = nil
            self.core.cancelPeripheralConnection(peripheral.core)
        }
        return
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
                return peripheral
            }
            self.delegate?.willRestore(state: restoreState, of: self)
        }
    }

    @objc public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.queue.async {
            if central.state == .poweredOn {
                // nothing for now
            } else if central.state == .poweredOff {
                for peripheral in self.peripherals.values {
                    if peripheral.state == .connected {
                        let delegate = peripheral as? PeripheralDelegate
                        delegate?.didDisconnect(from: peripheral, error: nil)
                    }
                }
            }

            if #available (iOS 10.0, iOSApplicationExtension 10.0, *) {
                let state = CentralManagerState(from: central.state)
                self.delegate?.didUpdate(state: state, of: self)
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
            self.delegate?.didDiscover(
                peripheral: wrapper,
                rssi: RSSI as! Int,
                with: self
            )
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
//            wrapper.attach(to: peripheral)
            let services = wrapper.automaticallyDiscoveredServices
            wrapper.discover(services: services)
            let delegate = wrapper as? PeripheralDelegate
            delegate?.didConnect(to: wrapper)
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
//            wrapper.detach(from: peripheral)
            let delegate = wrapper as? PeripheralDelegate
            delegate?.didFailToConnect(to: wrapper, error: error)
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
//            wrapper.detach(from: peripheral)
            let delegate = wrapper as? PeripheralDelegate
            delegate?.didDisconnect(from: wrapper, error: error)
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
            self.delegate?.didRetrieve(peripherals: peripherals, from: self)
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
            self.delegate?.didRetrieve(connectedPeripherals: peripherals, from: self)
        }
    }
}

// MARK: - Responder:
extension CentralManager: Responder {
    internal var nextResponder: Responder? {
        return nil
    }
}
