//
//  CBPeripheralMock.swift
//  BluesTests
//
//  Created by Michał Kałużny on 13/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import CoreBluetooth
@testable import Blues

class CBPeripheralMock: CorePeripheralProtocol {
    var identifier: UUID = UUID()
    
    var delegate: CBPeripheralDelegate? = nil
    var name: String? = nil
    var rssi: NSNumber? = nil
    var state: CBPeripheralState = .disconnected
    var services: [CBService]? = nil
    var canSendWriteWithoutResponse: Bool = false
    
    func readRSSI() {
        
    }
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        
    }
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService) {
        
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {
        
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
