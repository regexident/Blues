//
//  DefaultService.swift
//  Blues
//
//  Created by Vincent Esche on 10.05.17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// Default implementation of `Service` protocol.
public class DefaultService: Service {

    public let shadow: ShadowService

    public weak var delegate: ServiceDelegate?
    public weak var dataSource: ServiceDataSource?

    public required init(shadow: ShadowService) {
        self.shadow = shadow
    }
}

extension DefaultService: ServiceDelegate {

    public func didDiscover(
        includedServices: Result<[Service], Error>,
        for service: Service
    ) {
        self.delegate?.didDiscover(includedServices: includedServices, for: service)
    }

    public func didDiscover(
        characteristics: Result<[Characteristic], Error>,
        for service: Service
    ) {
        self.delegate?.didDiscover(characteristics: characteristics, for: service)
    }
}

extension DefaultService: ServiceDataSource {
    
    public func characteristic(
        shadow: ShadowCharacteristic,
        for service: Service
    ) -> Characteristic {
        if let dataSource = self.dataSource {
            return dataSource.characteristic(shadow: shadow, for: service)
        } else {
            return DefaultCharacteristic(shadow: shadow)
        }
    }
}
