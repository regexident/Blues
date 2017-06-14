//
//  ServiceNames.swift
//  Blues
//
//  Created by Vincent Esche on 29/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import Blues

open class ServiceNames {
    static let namesByIdentifier = [
        "1811": "Alert Notification",
        "1815": "Automation IO",
        "180F": "Battery",
        "1810": "Blood Pressure",
        "181B": "Body Composition",
        "181E": "Bond Management",
        "181F": "Continuous Glucose Monitoring",
        "1805": "Current Time",
        "1818": "Cycling Power",
        "1816": "Cycling Speed and Cadence",
        "180A": "Device Information",
        "181A": "Environmental Sensing",
        "1800": "Generic Access",
        "1801": "Generic Attribute",
        "1808": "Glucose",
        "1809": "Health Thermometer",
        "180D": "Heart Rate",
        "1823": "HTTP Proxy",
        "1812": "Human Interface Device",
        "1802": "Immediate Alert",
        "1821": "Indoor Positioning",
        "1820": "Internet Protocol Support",
        "1803": "Link Loss",
        "1819": "Location and Navigation",
        "1807": "Next DST Change",
        "1825": "Object Transfer",
        "180E": "Phone Alert Status",
        "1822": "Pulse Oximeter",
        "1806": "Reference Time Update",
        "1814": "Running Speed and Cadence",
        "1813": "Scan Parameters",
        "1824": "Transport Discovery",
        "1804": "Tx Power",
        "181C": "User Data",
        "181D": "Weight Scale",
    ]

    public static func nameOf(service: Identifier) -> String? {
        return self.namesByIdentifier[service.string]
    }
}
