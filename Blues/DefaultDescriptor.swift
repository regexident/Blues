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

// MARK: - DescriptorReadingDelegate
extension DefaultDescriptor: DescriptorReadingDelegate {
    public func didUpdate(any: Result<Any, Error>, for descriptor: Descriptor) {
        if let delegate = self.delegate as? DescriptorReadingDelegate {
            delegate.didUpdate(any: any, for: descriptor)
        }
    }
}

// MARK: - DescriptorWritingDelegate
extension DefaultDescriptor: DescriptorWritingDelegate {
    public func didWrite(any: Result<Any, Error>, for descriptor: Descriptor) {
        if let delegate = self.delegate as? DescriptorWritingDelegate {
            delegate.didWrite(any: any, for: descriptor)
        }
    }
}
