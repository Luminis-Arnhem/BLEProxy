import Foundation
import CoreBluetooth

class BleCharacteristic {
    init(uuid: CBUUID) {
        self.uuid = uuid
    }
    
    let uuid: CBUUID
    var characteristic: CBCharacteristic?
}
