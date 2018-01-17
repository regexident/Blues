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
    
    var genericServices: [CoreServiceProtocol]? { get }
    
    var canSendWriteWithoutResponse: Bool { get }
    
    func readRSSI()
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CoreServiceProtocol)
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CoreServiceProtocol)
    
    func readValue(for characteristic: CBCharacteristic)
    
    @available(iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    
    func discoverDescriptors(for characteristic: CBCharacteristic)
    
    func readValue(for descriptor: CBDescriptor)
    
    func writeValue(_ data: Data, for descriptor: CBDescriptor)
    
    @available(iOS 11.0, watchOS 4.0, *)
    func openL2CAPChannel(_ PSM: CBL2CAPPSM)
}

internal protocol CorePeripheralDelegateProtocol: class {
    @available(iOS 6.0, *)
    func corePeripheralDidUpdateName(_ peripheral: CorePeripheralProtocol)
    
    @available(iOS 7.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didModifyServices invalidatedServices: [CoreServiceProtocol])
    
    @available(iOS 8.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didReadRSSI RSSI: NSNumber, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didDiscoverServices error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didDiscoverIncludedServicesFor service: CBService, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didUpdateValueFor descriptor: CBDescriptor, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CorePeripheralProtocol, didWriteValueFor descriptor: CBDescriptor, error: Error?)
}

extension CorePeripheralProtocol {
    public static func ==(lhs: CorePeripheralProtocol, rhs: CorePeripheralProtocol) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension CBPeripheral: CorePeripheralProtocol {
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CoreServiceProtocol) {
        guard let service = protocolCast(service, to: CBService.self) else {
            return
        }
        
        discoverIncludedServices(includedServiceUUIDs, for: service)
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CoreServiceProtocol) {
        guard let service = protocolCast(service, to: CBService.self) else {
            return
        }
        
        discoverCharacteristics(characteristicUUIDs, for: service)
    }
    
    var genericServices: [CoreServiceProtocol]? {
        return services
    }
}

