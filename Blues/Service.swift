//
//  Service.swift
//  Blues
//
//  Created by Vincent Esche on 26/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public class DefaultService: Service, DelegatedService {
    public let shadow: ShadowService
    public weak var delegate: ServiceDelegate?

    public required init(shadow: ShadowService) {
        self.shadow = shadow
    }

    public func makeCharacteristic(shadow: ShadowCharacteristic) -> Characteristic {
        return DefaultCharacteristic(shadow: shadow)
    }
}

extension DefaultService: ServiceDelegate {

    public func didDiscover(includedServices: Result<[Service], Error>, forService service: Service) {
        self.delegate?.didDiscover(includedServices: includedServices, forService: service)
    }

    public func didDiscover(characteristics: Result<[Characteristic], Error>, forService service: Service) {
        self.delegate?.didDiscover(characteristics: characteristics, forService: service)
    }
}

extension DefaultService: CustomStringConvertible {
    public var description: String {
        let attributes = [
            "uuid = \(self.shadow.uuid)",
            "name = \(self.name ?? "<nil>")",
        ].joined(separator: ", ")
        return "<DefaultService \(attributes)>"
    }
}

public protocol Service: class, ServiceDelegate {
    var name: String? { get }
    var shadow: ShadowService { get }

    init(shadow: ShadowService)

    func makeCharacteristic(shadow: ShadowCharacteristic) -> Characteristic
}

extension Service {
    public var uuid: Identifier {
        return self.shadow.uuid
    }

    public var name: String? {
        return nil
    }

    var isPrimary: Result<Bool, PeripheralError> {
        return self.core.map {
            $0.isPrimary
        }
    }

    public var characteristics: [Identifier: Characteristic] {
        return self.shadow.characteristics
    }

    public var peripheral: Peripheral? {
        return self.shadow.peripheral
    }

    var nextResponder: Responder? {
        return self.shadow.peripheral as! Responder?
    }

    public func discover(includedServices: [Identifier]?) -> Result<(), PeripheralError> {
        return (self as! Responder).tryToHandle(DiscoverIncludedServicesMessage(
            uuids: includedServices,
            service: self
        )) ?? .err(.unhandled)
    }

    public func discover(characteristics: [Identifier]?) -> Result<(), PeripheralError> {
        return (self as! Responder).tryToHandle(DiscoverCharacteristicsMessage(
            uuids: characteristics,
            service: self
        )) ?? .err(.unhandled)
    }

    var core: Result<CBService, PeripheralError> {
        return self.shadow.core.okOr(.unreachable)
    }
}

public protocol DelegatedService: Service {
    weak var delegate: ServiceDelegate? { get set }
}

public protocol ServiceDelegate: class {
    func didDiscover(includedServices: Result<[Service], Error>, forService service: Service)
    func didDiscover(characteristics: Result<[Characteristic], Error>, forService service: Service)
}

public class ShadowService {
    public let uuid: Identifier
    weak var core: CBService?
    weak var peripheral: Peripheral?

    var characteristics: [Identifier: Characteristic] = [:]
    var includedServices: [Identifier: Service] = [:]

    init(core: CBService, peripheral: Peripheral) {
        self.uuid = Identifier(uuid: core.uuid)
        self.core = core
        self.peripheral = peripheral
    }

    func attach(core: CBService) {
        self.core = core
        guard let cores = core.characteristics else {
            return
        }
        for core in cores {
            let uuid = Identifier(uuid: core.uuid)
            guard let characteristic = self.characteristics[uuid] else {
                continue
            }
            characteristic.shadow.attach(core: core)
        }
    }

    func detach() {
        self.core = nil
        for characteristic in self.characteristics.values {
            characteristic.shadow.detach()
        }
    }
}
