import CoreBluetooth
import Combine


protocol DiffuserAPI {
    /// Service UUIDs to scan for
    var scanServiceUUIDs: [CBUUID] { get }
    var requestEquipmentVersionByte: UInt8 { get }
    var validStartBytes: Set<UInt8> { get }
    var responseHandlers: [UInt8: (Data) -> Void] { get }
    func saveDeviceModel(peripheralUUID: String, model: String)
    func loadDeviceModel(peripheralUUID: String) -> String?
    func startScanning(manager: CBCentralManager)
    func writeAndVerifySettings(peripheral: CBPeripheral, characteristic: CBCharacteristic, writeCommand: [UInt8])
    func requestEquipmentVersion(peripheral: CBPeripheral, characteristic: CBCharacteristic?)
    func parseResponse(_ data: Data)
    func sendOldProtocolPassword(peripheral: CBPeripheral, characteristic: CBCharacteristic, password: String)
    func sendNewProtocolPassword(peripheral: CBPeripheral, characteristic: CBCharacteristic, password: String, customCode: String)
    func sendPairingPassword(peripheral: CBPeripheral, characteristic: CBCharacteristic, customCode: String)
}
