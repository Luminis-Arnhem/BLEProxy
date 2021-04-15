import Foundation
import CoreBluetooth

protocol BleCentralDelegate {
    func connected()
    func disconnected(reason: String)
    func dataRead(data: Data)
    func dataWritten()
    func dataReceivedFromPeripheral(data: Data)
    func logMessage(message: String)
}

class BleCentral: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var delegate: BleCentralDelegate?
    
    private var centralManager: CBCentralManager?
    private var peripheralName: String?
    private var peripheral: CBPeripheral?
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func connect() {
        self.peripheralName = BleConstants.DEVICE_NAME
        if self.centralManager?.state == .poweredOn && !(self.centralManager?.isScanning ?? false) {
            self.delegate?.logMessage(message: "Started scanning for BLE peripherals.")
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func disconnect() {
        self.peripheralName = nil
        self.stopScanning()
        if let peripheral = self.peripheral {
            if peripheral.state == .connected || peripheral.state == .connecting {
                self.centralManager?.cancelPeripheralConnection(peripheral)
            }
        }
    }

    private func stopScanning() {
        if (self.centralManager?.isScanning ?? false) {
            self.delegate?.logMessage(message: "Stopped scanning for BLE peripherals.")
            self.centralManager?.stopScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name?.lowercased(), let gapName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)?.lowercased(), let peripheralName = self.peripheralName?.lowercased() else { return }
        self.delegate?.logMessage(message: "BLE peripheral found with names: [\(name),\(gapName)].")
        if peripheral.state != .connected && (name == peripheralName || gapName == peripheralName) {
            self.stopScanning()
            self.delegate?.logMessage(message: "Connecting to peripheral \(peripheral).")
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            self.centralManager?.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegate?.logMessage(message: "Connected to peripheral \(peripheral), discovering services.")
        self.peripheral?.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.delegate?.disconnected(reason: "Connection to peripheral \(peripheral) failed with error: \(error.debugDescription)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.delegate?.disconnected(reason: "Connection to peripheral \(peripheral) closed with error: \(error).")
        } else {
            self.delegate?.disconnected(reason: "Connection to peripheral \(peripheral) closed.")
        }
    }
    
    func readData(characteristicUUID: CBUUID) {
        
    }
    
    func writeData(characteristicUUID: CBUUID, data: Data) {
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && self.peripheralName != nil && !central.isScanning {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
}
