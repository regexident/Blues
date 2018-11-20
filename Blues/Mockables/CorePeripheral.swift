// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreBluetooth

protocol CBPeripheralProtocol: class, CBPeerProtocol {
    
    var delegate: CBPeripheralDelegate? { get set }
    
    var name: String? { get }
    
    @available(iOS, introduced: 5.0, deprecated: 8.0)
    var rssi: NSNumber? { get }
    
    var state: CBPeripheralState { get }
    
    var genericServices: [CBServiceProtocol]? { get }
    
    var canSendWriteWithoutResponse: Bool { get }
    
    func readRSSI()
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBServiceProtocol)
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceProtocol)
    
    func readValue(for characteristic: CBCharacteristic)
    
    @available(iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    
    func discoverDescriptors(for characteristic: CBCharacteristic)
    
    func readValue(for descriptor: CBDescriptor)
    
    func writeValue(_ data: Data, for descriptor: CBDescriptor)
    
    @available(iOS 11.0, watchOS 4.0, macOS 10.14, tvOS 11.0, *)
    func openL2CAPChannel(_ PSM: CBL2CAPPSM)
}

internal protocol CBPeripheralDelegateProtocol: class {
    @available(iOS 6.0, *)
    func corePeripheralDidUpdateName(_ peripheral: CBPeripheralProtocol)
    
    @available(iOS 7.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didModifyServices invalidatedServices: [CBServiceProtocol])
    
    @available(iOS 8.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didReadRSSI RSSI: NSNumber, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didDiscoverServices error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didDiscoverIncludedServicesFor service: CBService, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didUpdateValueFor descriptor: CBDescriptor, error: Error?)
    
    @available(iOS 5.0, *)
    func corePeripheral(_ peripheral: CBPeripheralProtocol, didWriteValueFor descriptor: CBDescriptor, error: Error?)
}

extension CBPeripheralProtocol {
    public static func ==(lhs: CBPeripheralProtocol, rhs: CBPeripheralProtocol) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension CBPeripheral: CBPeripheralProtocol {
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBServiceProtocol) {
        guard let coreService = protocolCast(service, to: CBService.self) else {
            return
        }
        
        self.discoverIncludedServices(includedServiceUUIDs, for: coreService)
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceProtocol) {
        guard let coreService = protocolCast(service, to: CBService.self) else {
            return
        }
        
        self.discoverCharacteristics(characteristicUUIDs, for: coreService)
    }
    
    var genericServices: [CBServiceProtocol]? {
        return self.services
    }
}
