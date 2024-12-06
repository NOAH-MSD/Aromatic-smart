//
//  BluetoothUtils.swift
//  aromatic-app
//

//

// Utilities/BluetoothUtils.swift
//
// Utilities.swift
// Helper functions for BluetoothManager integration
//

import Foundation

/// Extract a UInt16 from a specific index in a data buffer
///
/// - Parameters:
///   - data: The data buffer to extract from
///   - index: The byte index to extract from
/// - Returns: The UInt16 value, or nil if the index is out of bounds
func extractUInt16(from data: Data, at index: Int) -> UInt16? {
    guard index + 1 < data.count else { return nil }
    return UInt16(data[index]) << 8 | UInt16(data[index + 1])
}

/// Extract a string from a range of bytes in the data buffer
///
/// - Parameters:
///   - data: The data buffer to extract from
///   - range: The byte range to extract
/// - Returns: The extracted string, or nil if the range is invalid
func extractString(from data: Data, range: Range<Int>) -> String? {
    guard range.lowerBound >= 0, range.upperBound <= data.count else { return nil }
    let subData = data.subdata(in: range)
    return String(data: subData, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters)
}

/// Decode the days of the week from a single byte
///
/// - Parameter byte: A byte where each bit represents a day (starting with Sunday at LSB)
/// - Returns: An array of strings representing the active days
func decodeDaysOfWeek(byte: UInt8) -> [String] {
    let days = [
        (byte & 0x01) != 0 ? "Sunday" : nil,
        (byte & 0x02) != 0 ? "Monday" : nil,
        (byte & 0x04) != 0 ? "Tuesday" : nil,
        (byte & 0x08) != 0 ? "Wednesday" : nil,
        (byte & 0x10) != 0 ? "Thursday" : nil,
        (byte & 0x20) != 0 ? "Friday" : nil,
        (byte & 0x40) != 0 ? "Saturday" : nil
    ]
    return days.compactMap { $0 }
}

/// Combine data packets and separate into header and body
///
/// - Parameter data: The combined data buffer
/// - Returns: A tuple containing the header (first two bytes) and the body (remaining bytes)
func parseCombinedData(_ data: Data) -> (header: Data, body: Data) {
    let header = data.prefix(2)
    let body = data.dropFirst(2)
    return (header, body)
}

/// Format the name of a Bluetooth peripheral
///
/// - Parameter name: The optional name of the peripheral
/// - Returns: A formatted string for the peripheral name
func formatPeripheralName(_ name: String?) -> String {
    return name ?? "Unnamed Device"
}

/// Create a command for the old pairing protocol
///
/// - Parameter password: The pairing password
/// - Returns: The generated command as Data
func createOldProtocolCommand(password: String) -> Data {
    var commandData = Data([0x8F])
    if let passwordData = password.data(using: .ascii) {
        commandData.append(passwordData)
    }
    return commandData
}

/// Create a command for the new pairing protocol
///
/// - Parameters:
///   - password: The pairing password
///   - customCode: The custom pairing code
/// - Returns: The generated command as Data
func createNewProtocolCommand(password: String, customCode: String) -> Data {
    var commandData = Data([0x8F])
    if let passwordData = password.data(using: .ascii),
       let customCodeData = customCode.data(using: .ascii) {
        commandData.append(passwordData)
        commandData.append(customCodeData)
    }
    return commandData
}

/// Print a formatted hex dump of the provided data
///
/// - Parameter data: The data buffer to print
func printHexDump(of data: Data) {
    let hexString = data.map { String(format: "%02x", $0) }.joined(separator: " ")
    print("Hex Dump: \(hexString)")
}
