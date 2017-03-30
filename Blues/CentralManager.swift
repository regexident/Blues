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
public class CentralManager: NSObject {

    private struct Constants {
        static let queueLabel = "com.nwtnberlin.blues.queue"
    }

    @available(iOS 10.0, *)
    @available(iOSApplicationExtension 10.0, *)
    public var state: CentralManagerState {
        return CentralManagerState(from: self.inner.state)
    }

    public var isScanning: Bool {
        return self.inner.isScanning
    }

    fileprivate(set) public var peripherals: [Identifier: Peripheral] = [:]

    fileprivate(set) public weak var dataSource: CentralManagerDataSource?
    fileprivate(set) public weak var delegate: CentralManagerDelegate?

    var inner: CBCentralManager!

    let queue = DispatchQueue(label: Constants.queueLabel, attributes: [])

    public init(
        delegate: CentralManagerDelegate? = nil,
        dataSource: CentralManagerDataSource? = nil,
        options: CentralManagerOptions? = nil
    ) {
        self.delegate = delegate
        self.dataSource = dataSource
        super.init()
        self.inner = CBCentralManager(
            delegate: self,
            queue: DispatchQueue.main, // global(qos: .background),
            options: options?.dictionary
        )
    }

    public func startScanningForPeripherals(
        advertisingWithServices services: [String]? = nil,
        options: CentralManagerScanningOptions? = nil
    ) {
        guard !self.inner.isScanning else {
            return
        }

        self.queue.async {
            let uuids = services?.map { CBUUID(string: $0) }
            self.inner.scanForPeripherals(withServices: uuids, options: options?.dictionary)
        }
    }

    public func stopScanningForPeripherals() {
        self.queue.async {
            self.inner.stopScan()
        }
    }

    public func retrievePeripherals(withIdentifiers identifiers: [Identifier]) -> [Peripheral] {
        let cbuuids = identifiers.map {
            $0.core.uuidString
        }
        let nsuuids = cbuuids.flatMap { UUID(uuidString: $0) }
        let innerPeripherals = self.inner.retrievePeripherals(withIdentifiers: nsuuids)
        let peripheralIdentifiers = innerPeripherals.map { CBUUID(nsuuid: $0.identifier) }
        return self.peripherals.flatMap { uuid, peripheral in
            peripheralIdentifiers.contains(uuid.core) ? peripheral : nil
        }
    }

    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [Identifier]) -> [Peripheral] {
        let cbuuids = serviceUUIDs.map { $0.core }
        let innerPeripherals = self.inner.retrieveConnectedPeripherals(withServices: cbuuids)
        let peripheralIdentifiers = innerPeripherals.map { CBUUID(nsuuid: $0.identifier) }
        return self.peripherals.flatMap { uuid, peripheral in
            peripheralIdentifiers.contains(uuid.core) ? peripheral : nil
        }
    }

    public func disconnectAll() {
        self.queue.async {
            let connectedPeripherals = self.peripherals.values.filter {
                $0.state == .connected
            }
            for peripheral in connectedPeripherals {
                let _ = self.disconnect(peripheral: peripheral)
            }
        }
    }

    func discoveredPeripheral(
        shadow: ShadowPeripheral,
        advertisement: Advertisement,
        forCentralManager centralManager: CentralManager
    ) -> Peripheral {
        let peripheral: Peripheral
        if let dataSource = centralManager.dataSource {
            peripheral = dataSource.discoveredPeripheral(
                shadow: shadow,
                advertisement: advertisement,
                forCentralManager: self
            )
        } else {
            peripheral = DefaultPeripheral(shadow: shadow)
        }
        peripheral.shadow.peripheral = peripheral
        self.peripherals[peripheral.identifier] = peripheral
        return peripheral
    }

    func restoredPeripheral(
        shadow: ShadowPeripheral,
        forCentralManager centralManager: CentralManager
        ) -> Peripheral {
        let peripheral: Peripheral
        if let dataSource = centralManager.dataSource {
            peripheral = dataSource.restoredPeripheral(shadow: shadow, forCentralManager: self)
        } else {
            peripheral = DefaultPeripheral(shadow: shadow)
        }
        peripheral.shadow.peripheral = peripheral
        self.peripherals[peripheral.identifier] = peripheral
        return peripheral
    }
}

// MARK: - CentralManagerHandling:
extension CentralManager: CentralManagerHandling {

    func connect(
        peripheral: Peripheral,
        options: ConnectionOptions? = nil
    ) -> Result<(), PeripheralError> {
        guard peripheral.state != .connected else {
            return .ok(())
        }
        self.queue.async {
            peripheral.willConnect(peripheral: peripheral)
            peripheral.shadow.connectionOptions = options
            let innerPeripheral = peripheral.core
            self.inner.connect(innerPeripheral, options: options?.dictionary)
        }
        return .ok(())
    }

    func disconnect(peripheral: Peripheral) -> Result<(), PeripheralError> {
        guard peripheral.state == .connected else {
            return .err(.unreachable)
        }
        self.queue.async {
            peripheral.willDisconnect(peripheral: peripheral)
            peripheral.shadow.connectionOptions = nil
            let innerPeripheral = peripheral.core
            self.inner.cancelPeripheralConnection(innerPeripheral)
        }
        return .ok(())
    }
}

// MARK: - CBCentralManagerDelegate:
extension CentralManager: CBCentralManagerDelegate {

    @objc public func centralManager(
        _ central: CBCentralManager,
        willRestoreState dictionary: [String: Any]
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            let restoreState = CentralManagerRestoreState(dictionary: dictionary) { core in
                let shadow = ShadowPeripheral(
                    core: core,
                    centralManager: self
                )
                return self.restoredPeripheral(shadow: shadow, forCentralManager: self)
            }
            self.delegate?.willRestore(state: restoreState, ofManager: self)
        }
    }

    @objc public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            if central.state == .poweredOn {
                // nothing for now
            } else if central.state == .poweredOff {
                let connectedPeripherals = self.peripherals.values.filter {
                    $0.state != .disconnected
                }
                for peripheral in connectedPeripherals {
                    peripheral.didDisconnect(peripheral: peripheral, error: nil)
                }
            }

            if #available (iOS 10.0, iOSApplicationExtension 10.0, *) {
                let state = CentralManagerState(from: central.state)
                self.delegate?.didUpdate(state: state, ofManager: self)
            }
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            let uuid = Identifier(uuid: peripheral.identifier)
            let wasAlreadyDiscovered = self.peripherals[uuid] != nil
            guard !wasAlreadyDiscovered else {
                return
            }
            let advertisement = Advertisement(dictionary: advertisementData)
            let shadow = ShadowPeripheral(
                core: peripheral,
                centralManager: self
            )
            let peripheral = self.discoveredPeripheral(
                shadow: shadow,
                advertisement: advertisement,
                forCentralManager: self
            )
            self.delegate?.didDiscover(
                peripheral: peripheral,
                advertisement: advertisement,
                rssi: RSSI as! Int,
                withManager: self
            )
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            let uuid = Identifier(uuid: peripheral.identifier)
            guard let peripheral = self.peripherals[uuid] else {
                return
            }
            peripheral.shadow.attach()
            let services = peripheral.automaticallyDiscoveredServices
            if case let .err(error) = peripheral.discover(services: services) {
                print("Error: \(error)")
            }
            peripheral.didConnect(peripheral: peripheral)
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            let uuid = Identifier(uuid: peripheral.identifier)
            guard let peripheral = self.peripherals[uuid] else {
                return
            }
            peripheral.shadow.detach()
            peripheral.didFailToConnect(peripheral: peripheral, error: error)
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Swift.Error?
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            let uuid = Identifier(uuid: peripheral.identifier)
            guard let peripheral = self.peripherals[uuid] else {
                return
            }
            peripheral.shadow.detach()
            peripheral.didDisconnect(peripheral: peripheral, error: error)
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didRetrievePeripherals peripherals: [CBPeripheral]
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            let peripherals: [Peripheral] = peripherals.flatMap { peripheral in
                let uuid = Identifier(uuid: peripheral.identifier)
                guard let peripheral = self.peripherals[uuid] else {
                    return nil
                }
                return peripheral
            }
            self.delegate?.didRetrieve(peripherals: peripherals, fromManager: self)
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didRetrieveConnectedPeripherals peripherals: [CBPeripheral]
    ) {
        #if DEBUG_PRINT
            print("\(String(describing: type(of: self))).\(#function)")
        #endif
        self.queue.async {
            let peripherals: [Peripheral] = peripherals.flatMap { peripheral in
                let uuid = Identifier(uuid: peripheral.identifier)
                guard let peripheral = self.peripherals[uuid] else {
                    return nil
                }
                return peripheral
            }
            self.delegate?.didRetrieve(connectedPeripherals: peripherals, fromManager: self)
        }
    }
}

// MARK: - Responder:
extension CentralManager: Responder {

    var nextResponder: Responder? {
        return nil
    }
}
