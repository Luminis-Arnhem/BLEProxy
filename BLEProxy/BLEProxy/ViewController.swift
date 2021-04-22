import Cocoa
import CoreBluetooth

class ViewController: NSViewController, BleCentralDelegate, BlePeripheralDelegate {
    
    @IBOutlet weak var startProxyButton: NSButton!
    @IBOutlet weak var stopProxyButton: NSButton!
    @IBOutlet weak var logView: NSTextField!
    
    var bleCentral: BleCentral?
    var blePeripheral: BlePeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.bleCentral = BleCentral()
        self.bleCentral?.delegate = self
        
        self.blePeripheral = BlePeripheral()
        self.blePeripheral?.delegate = self
    }

    @IBAction func startProxy(_ sender: Any) {
        startProxyButton.isEnabled = false
        stopProxyButton.isEnabled = true
        self.bleCentral?.connect()
    }
    
    @IBAction func stopProxy(_ sender: Any) {
        startProxyButton.isEnabled = true
        stopProxyButton.isEnabled = false
        self.bleCentral?.disconnect()
    }
    
    @IBAction func clearLog(_ sender: Any) {
        self.logView.stringValue = ""
    }
    
    func connected(services: [BleService]) {
        log("Connected to peripheral")
        self.blePeripheral?.startAdvertising(services: services)
    }
    
    func disconnected(reason: String) {
        log("Stopped because: \(reason)")
        self.blePeripheral?.stopAdvertising()
    }
    
    func advertisingStarted() {
        log("Started advertising peripheral")
    }
    
    func advertisingStopped(reason: String) {
        log("Stopped advertising because: \(reason)")
    }
    
    func read(fromCharacteristicUUID uuid: CBUUID) {
        log("Reading data from characteristic \(uuid.uuidString)")
        self.bleCentral?.readData(characteristicUUID: uuid)
    }
    
    func write(data: Data, toCharacteristicUUID uuid: CBUUID) {
        log("Writing data \(data) from central to peripheral on characteristic \(uuid.uuidString)")
        self.bleCentral?.writeData(characteristicUUID: uuid, data: data, writeType: .withResponse)
    }
    
    func registerForNotifications(onCharacteristicWithUUID uuid: CBUUID) {
        log("Registering for notifications on characteristic \(uuid.uuidString)")
        self.bleCentral?.registerForNotifications(characteristicUUID: uuid)
    }
    
    func unregisterFromNotifications(onCharacteristicWithUUID uuid: CBUUID) {
        log("Unregistering from notifications on characteristic \(uuid.uuidString)")
        self.bleCentral?.unregisterFromNotifications(characteristicUUID: uuid)
    }
    
    func dataWritten(onCharacteristicWithUUID uuid: CBUUID, withResult result: CBATTError.Code) {
        log("Data written from central to peripheral on characteristic \(uuid.uuidString) with result: \(result)")
        self.blePeripheral?.confirmWriteRequest(onCharacteristicUUID: uuid, withResult: result)
    }
    
    func dataReceived(data: Data, onCharacteristicWithUUID uuid: CBUUID) {
        log("Received \(data) from peripheral to pass to central on characteristic \(uuid.uuidString)")
        self.blePeripheral?.dataReceived(data: data, onCharacteristicUUID: uuid)
    }
    
    func logMessage(message: String) {
        log(message)
    }
    
    private func log(_ message: String) {
        logView.stringValue.append("\(message)\n")
    }
}
