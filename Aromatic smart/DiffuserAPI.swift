import CoreBluetooth
import Combine

/// A protocol describing all the operations needed by a diffuser type.
/// For example, Type A or Type B.
protocol DiffuserAPI {
    /// Service UUIDs to scan for
    var scanServiceUUIDs: [CBUUID] { get }
    /// Byte command for requesting equipment version
    var requestEquipmentVersionByte: UInt8 { get }
    /// Valid start bytes recognized by this diffuser type
    var validStartBytes: Set<UInt8> { get }
    /// Response handlers mapped to each recognized start byte
    var responseHandlers: [UInt8: (Data) -> Void] { get }

    func startScanning(manager: CBCentralManager)
    func requestEquipmentVersion(peripheral: CBPeripheral, characteristic: CBCharacteristic?)
    func parseResponse(_ data: Data)
}
