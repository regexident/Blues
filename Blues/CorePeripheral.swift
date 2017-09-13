//
//  CorePeripheral.swift
//  Blues
//
//  Created by Michał Kałużny on 13/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import CoreBluetooth

protocol CorePeripheralProtocol: class, CorePeerProtocol {
    
    var delegate: CBPeripheralDelegate? { get set }
    
    var name: String? { get }
    
    @available(iOS, introduced: 5.0, deprecated: 8.0)
    var rssi: NSNumber? { get }
    
    var state: CBPeripheralState { get }
    
    var services: [CBService]? { get }
    
    var canSendWriteWithoutResponse: Bool { get }
    
    func readRSSI()
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    
    func readValue(for characteristic: CBCharacteristic)
    
    @available(iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    
    func discoverDescriptors(for characteristic: CBCharacteristic)
    
    func readValue(for descriptor: CBDescriptor)
    
    func writeValue(_ data: Data, for descriptor: CBDescriptor)
    
    @available(iOS 11.0, *)
    func openL2CAPChannel(_ PSM: CBL2CAPPSM)
}

extension CorePeripheralProtocol {
    public static func ==(lhs: CorePeripheralProtocol, rhs: CorePeripheralProtocol) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension CBPeripheral: CorePeripheralProtocol {}

