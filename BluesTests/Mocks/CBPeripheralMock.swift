// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreBluetooth
@testable import Blues

class CBPeripheralMock: CBPeripheralProtocol {
    enum Error: Swift.Error {
        case unknown
    }
    
    var identifier: UUID = UUID()
    var genericDelegate: CBPeripheralDelegateProtocol? = nil
    var delegate: CBPeripheralDelegate? = nil
    var name: String? = nil
    var rssi: NSNumber? = 0
    var state: CBPeripheralState = .disconnected
    var genericServices: [CBServiceProtocol]? = nil
    var canSendWriteWithoutResponse: Bool = false
    
    var discoverableServices: [CBUUID] = []
    var disoverableIncludedServices: [CBUUID] = []

    var discoverServicesWasCalled = false
    var shouldFailReadingRSSI = false
    
    func readRSSI() {
        if self.shouldFailReadingRSSI {
            self.genericDelegate?.corePeripheral(self, didReadRSSI: 0, error: Error.unknown)
        } else {
            self.genericDelegate?.corePeripheral(self, didReadRSSI: rssi!, error: nil)
        }
    }
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        self.discoverServicesWasCalled = true
        if serviceUUIDs == nil {
            self.genericServices = self.discoverableServices.map { CBServiceMock.init(peripheral: self, uuid: $0) }
        } else {
            self.genericServices = self.discoverableServices.filter {
                serviceUUIDs!.contains($0)
            }.map { CBServiceMock.init(peripheral: self, uuid: $0) }
        }
        
        self.genericDelegate?.corePeripheral(self, didDiscoverServices: nil)
    }
    
    func modify(service: CBUUID) {
        self.genericDelegate?.corePeripheral(self, didModifyServices: [CBServiceMock.init(peripheral: self, uuid: service)])
    }
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBServiceProtocol) {
        
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceProtocol) {
        
    }
    
    func readValue(for characteristic: CBCharacteristic) {
        
    }
    
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return 15
    }
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        
    }
    
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        
    }
    
    func discoverDescriptors(for characteristic: CBCharacteristic) {
        
    }
    
    func readValue(for descriptor: CBDescriptor) {
        
    }
    
    func writeValue(_ data: Data, for descriptor: CBDescriptor) {
        
    }
    
    func openL2CAPChannel(_ PSM: CBL2CAPPSM) {
        
    }
}
