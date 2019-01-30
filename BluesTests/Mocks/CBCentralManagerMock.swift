// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreBluetooth

@testable import Blues

class CBCentralManagerMock: CBCentralManagerProtocol {
    required convenience init() {
        self.init(delegate: nil, queue: nil, options: nil)
    }
    
    var delegate: CBCentralManagerDelegate? = nil
    var genericDelegate: CBCentralCentralManagerDelegateProtocol? = nil
    
    var isScanning: Bool = false
    var state: CBManagerState = .poweredOn {
        didSet {
            self.genericDelegate?.coreCentralManagerDidUpdateState(self)
        }
    }
    
    var peripherals: [CBPeripheralProtocol] = []
    var shouldFailOnConnect: Bool = false
    
    required convenience init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?) {
        self.init(delegate: delegate, queue: queue, options: nil)
    }
    
    required init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]?) {}
    
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralProtocol] {
        return peripherals
            .filter { identifiers.contains($0.identifier) }
    }
    
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralProtocol] {
        let uuids = Set(serviceUUIDs)
        return peripherals
            .filter {
                guard let servicesArray = $0.genericServices else {
                    return false
                }
                
                let services = Set(servicesArray.map { $0.uuid} )
                let common = services.union(uuids)
                
                return common.count > 0
            }
    }
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
        self.isScanning = true
    }
    
    func stopScan() {
        self.isScanning = false
    }
    
    func connect(_ peripheral: CBPeripheralProtocol, options: [String : Any]?) {
        if shouldFailOnConnect {
            self.genericDelegate?.coreCentralManager(self, didFailToConnect: peripheral, error: nil)
        } else {
            self.genericDelegate?.coreCentralManager(self, didConnect: peripheral)
        }
    }
    
    func cancelPeripheralConnection(_ peripheral: CBPeripheralProtocol) {
        self.peripherals = peripherals.filter { $0.identifier != peripheral.identifier }
        self.genericDelegate?.coreCentralManager(self, didDisconnectPeripheral: peripheral, error: nil)
    }
    
    func discover(_ peripheral: CBPeripheralProtocol, advertisement: [String: Any]) {
        self.peripherals.append(peripheral)
        self.genericDelegate?.coreCentralManager(self, didDiscover: peripheral, advertisementData: advertisement, rssi: 100)
    }
    
    func restore(state: [String: Any]) {
        self.genericDelegate?.coreCentralManager(self, willRestoreState: state)
    }
}
