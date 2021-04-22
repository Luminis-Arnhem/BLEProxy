import Foundation
import CoreBluetooth

class BleConstants {
    static let DEVICE_NAME = "<the BLE advertising name of your BLE peripheral device>"
    
    static var SERVICES_AND_CHARACTERISTICS = [
        // Services
        CBUUID(string: "<service UUID>"): [
            // Characteristics
            CBUUID(string: "<characteristic UUID>"),
            CBUUID(string: "<characteristic UUID>")
        ]
    ]
}
