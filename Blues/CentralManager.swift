//
//  CentralManager.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Abstraction layer around `CBCentralManager`.
public class CentralManager: NSObject {

    private struct Constants {
        static let queueLabel = "com.nwtnberlin.blues.queue"
        static let sharedRestoreIdentifier = "com.nwtnberlin.blues.sharedRestoreIdentifier"
    }

    public var state: CentralManagerState {
        return CentralManagerState(from: self.inner.state)
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
            queue: self.queue,
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

    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
        let innerPeripherals = self.inner.retrievePeripherals(withIdentifiers: identifiers)
        let peripheralIdentifiers = innerPeripherals.map { CBUUID(nsuuid: $0.identifier) }
        return self.peripherals.flatMap { uuid, peripheral in
            peripheralIdentifiers.contains(uuid.core) ? peripheral : nil
        }
    }

    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [Peripheral] {
        let innerPeripherals = self.inner.retrieveConnectedPeripherals(withServices: serviceUUIDs)
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

    func peripheral(
        shadow: ShadowPeripheral,
        forCentralManager centralManager: CentralManager
    ) -> Peripheral {
        let peripheral: Peripheral
        if let dataSource = centralManager.dataSource {
            peripheral = dataSource.peripheral(shadow: shadow, forCentralManager: self)
        } else {
            peripheral = DefaultPeripheral(shadow: shadow)
        }
        peripheral.shadow.peripheral = peripheral
        self.peripherals[peripheral.uuid] = peripheral
        return peripheral
    }
}

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
            peripheral.shadow.connectionOptions = nil
            let innerPeripheral = peripheral.core
            self.inner.cancelPeripheralConnection(innerPeripheral)
        }
        return .ok(())
    }
}

extension CentralManager: CBCentralManagerDelegate {

    @objc public func centralManager(
        _ central: CBCentralManager,
        willRestoreState dictionary: [String: Any]
    ) {
        self.queue.async {
            let restoreState = CentralManagerRestoreState(dictionary: dictionary) { core in
                let shadow = ShadowPeripheral(
                    core: core,
                    centralManager: self,
                    advertisement: nil
                )
                return self.peripheral(shadow: shadow, forCentralManager: self)
            }
            self.delegate?.willRestore(state: restoreState, ofManager: self)
        }
    }

    @objc public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.didUpdateStateToPoweredOn()
        } else if central.state == .poweredOff {
            self.didUpdateStateToPoweredOff()
        }

        if #available (iOSApplicationExtension 10.0, *) {
            let state = CentralManagerState(from: central.state)
            self.delegate?.didUpdate(state: state, ofManager: self)
        }
    }

    private func didUpdateStateToPoweredOn() {
        // nothing for now
    }

    private func didUpdateStateToPoweredOff() {
        let connectedPeripherals = self.peripherals.values.filter {
            $0.state != .disconnected
        }
        for peripheral in connectedPeripherals {
            peripheral.didDisconnect(peripheral: peripheral, error: nil)
        }
    }

    private func hasAlreadyDiscovered(peripheral: CBPeripheral) -> Bool {
        let uuid = Identifier(uuid: peripheral.identifier)
        return self.peripherals[uuid] != nil
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        self.queue.async {
            guard !self.hasAlreadyDiscovered(peripheral: peripheral) else {
                return
            }
            let advertisement = Advertisement(dictionary: advertisementData)
            let shadow = ShadowPeripheral(
                core: peripheral,
                centralManager: self,
                advertisement: advertisement
            )
            let peripheral = self.peripheral(shadow: shadow, forCentralManager: self)
            self.delegate?.didDiscover(
                peripheral: peripheral,
                advertisement: advertisement,
                rssi: RSSI as Int,
                withManager: self
            )
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        self.queue.async {
            let uuid = Identifier(uuid: peripheral.identifier)
            guard let peripheral = self.peripherals[uuid] else {
                return
            }
            peripheral.shadow.attach()
            peripheral.didConnect(peripheral: peripheral)
        }
    }

    @objc public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Swift.Error?
    ) {
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
        self.queue.async {
            let uuid = Identifier(uuid: peripheral.identifier)
            guard let peripheral = self.peripherals[uuid] else {
                return
            }
            peripheral.shadow.detach()
            peripheral.didDisconnect(peripheral: peripheral, error: error)
        }
    }
}

extension CentralManager: Responder {

    var nextResponder: Responder? {
        return nil
    }
}
