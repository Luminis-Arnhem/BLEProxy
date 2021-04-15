import Foundation
import CoreBluetooth

class BleService {
    init(uuid: CBUUID) {
        self.uuid = uuid
    }
    
    let uuid: CBUUID
    var service: CBService?
    var characteristics: [BleCharacteristic]?
}
