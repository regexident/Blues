// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth
import CoreLocation

extension Advertisement {
    #if os(iOS)
    /// A type-safe representation of a Bluetooth Low Energy advertisement.
    @available(iOS 7.0, *)
    public init(
        beaconRegion: CLBeaconRegion,
        measuredPower: Double? = nil
    ) {
        let measuredPower = measuredPower.map { $0 as NSNumber }
        let nsMutableDictionary = beaconRegion.peripheralData(withMeasuredPower: measuredPower)
        guard let dictionary = nsMutableDictionary as? [String : Any] else {
            fatalError()
        }
        self.init(dictionary: dictionary)
    }
    #endif
}
