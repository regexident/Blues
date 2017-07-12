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
open class DefaultDescriptor: Descriptor, DelegatedDescriptorProtocol {
    public weak var delegate: DescriptorDelegate?
}

// MARK: - ReadableDescriptorDelegate
extension DefaultDescriptor: ReadableDescriptorDelegate {
    public func didUpdate(any: Result<Any, Error>, for descriptor: Descriptor) {
        self.delegate?.didUpdate(any: any, for: descriptor)
    }
}

// MARK: - WritableDescriptorDelegate
extension DefaultDescriptor: WritableDescriptorDelegate {
    public func didWrite(any: Result<Any, Error>, for descriptor: Descriptor) {
        self.delegate?.didWrite(any: any, for: descriptor)
    }
}
