//
//  DefaultDescriptor.swift
//  Blues
//
//  Created by Vincent Esche on 10.05.17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// Default implementation of `Descriptor` protocol.
public class DefaultDescriptor: Descriptor {

    public let shadow: ShadowDescriptor

    public weak var delegate: FullblownDescriptorDelegate?

    public required init(shadow: ShadowDescriptor) {
        self.shadow = shadow
    }
}

extension DefaultDescriptor: ReadableDescriptorDelegate {

    public func didUpdate(any: Result<Any, Error>, for descriptor: Descriptor) {
        self.delegate?.didUpdate(any: any, for: descriptor)
    }
}

extension DefaultDescriptor: WritableDescriptorDelegate {

    public func didWrite(any: Result<Any, Error>, for descriptor: Descriptor) {
        self.delegate?.didWrite(any: any, for: descriptor)
    }
}
