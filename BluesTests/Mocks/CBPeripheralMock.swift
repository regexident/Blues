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
    enum Error: Swift.Error {
        case unknown
    }
    
    var identifier: UUID = UUID()
    var genericDelegate: CorePeripheralDelegateProtocol? = nil
    var delegate: CBPeripheralDelegate? = nil
    var name: String? = nil
    var rssi: NSNumber? = 0
    var state: CBPeripheralState = .disconnected
    var genericServices: [CoreServiceProtocol]? = nil
    var canSendWriteWithoutResponse: Bool = false
    
    var discoverableServices: [CBUUID] = []
    var disoverableIncludedServices: [CBUUID] = []

    var discoverServicesWasCalled = false
    var shouldFailReadingRSSI = false
    
    func readRSSI() {
        if shouldFailReadingRSSI {
            genericDelegate?.corePeripheral(self, didReadRSSI: 0, error: Error.unknown)
        } else {
            genericDelegate?.corePeripheral(self, didReadRSSI: rssi!, error: nil)
        }
    }
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        discoverServicesWasCalled = true
        if serviceUUIDs == nil {
            genericServices = discoverableServices.map { CBServiceMock.init(peripheral: self, uuid: $0) }
        } else {
            genericServices = discoverableServices.filter {
                serviceUUIDs!.contains($0)
            }.map { CBServiceMock.init(peripheral: self, uuid: $0) }
        }
        
        genericDelegate?.corePeripheral(self, didDiscoverServices: nil)
    }
    
    func modify(service: CBUUID) {
        genericDelegate?.corePeripheral(self, didModifyServices: [CBServiceMock.init(peripheral: self, uuid: service)])
    }
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CoreServiceProtocol) {
        
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CoreServiceProtocol) {
        
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
