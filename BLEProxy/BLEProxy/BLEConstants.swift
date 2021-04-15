import Foundation
import CoreBluetooth

class BleConstants {
    static let DEVICE_NAME = "<the BLE advertising name of your BLE peripheral device>"
    
    static var SERVICES_AND_CHARACTERISTICS = [
        // Services
        CBUUID(string: "A6B80001-AC25-4F3C-AA25-9121AB9C5D18"): [
            // Characteristics
            CBUUID(string: "A6B80002-AC25-4F3C-AA25-9121AB9C5D18"),
            CBUUID(string: "A6B80002-AC25-4F3C-AA25-9121AB9C5D18")
        ]
    ]
}
