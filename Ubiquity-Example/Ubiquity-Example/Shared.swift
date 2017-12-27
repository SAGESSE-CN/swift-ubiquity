//
//  Shared.swift
//  Ubiquity-Example
//
//  Created by SAGESSE on 11/23/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


public class Shared: NSObject {

    public static func listen(_ address: String, port: UInt16 = 0) -> Shared {
        let shared = Shared(address: address, port: port)
        
        if port != 0 {
            var reused = true
            // Settings allow reuse of local addresses and ports.
            setsockopt(CFSocketGetNative(shared._socket), SOL_SOCKET, SO_REUSEADDR, &reused, socklen_t(MemoryLayout.size(ofValue: reused)))
            
            // Bind address for socket.
            CFSocketSetAddress(shared._socket, shared._address)
        } else {
            // Bind address for socket.
            CFSocketSetAddress(shared._socket, shared._address)

            // Copy reveal address for socket.
            shared._address = CFSocketCopyAddress(shared._socket)
        }
        
        return shared
    }
    
    public static func connect(_ address: Data) -> Shared {
        let shared = Shared(address: address as CFData, backType: [])
        return shared
    }
    public static func connect(_ address: String, port: UInt16)  -> Shared {
        let shared = Shared(address: address, port: port, backType: [])
        return shared
    }
    
    public func send(_ data: Any?) -> Any? {
        do {
            try _SharedDataSend(_socket, to: address, data: _encode(data))
            let data = try _SharedDataRecv(_socket)
            return _decode(data)
        } catch  {
            return nil
        }
    }
    public func respond(_ data: Any?) {
        _respondData = data
    }
    
    public func recive(_ closure: @escaping (Shared, Any?) -> Void) {
        _respond = closure
    }
    
    private init(address: CFData, backType: CFSocketCallBackType = .dataCallBack) {
        _address = address
        super.init()
        _socket = {
            var context = CFSocketContext()
            
            context.version = 0
            context.info = Unmanaged.passUnretained(self).toOpaque()
            
            return withUnsafePointer(to: &context) {
                return CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, backType.rawValue, _SharedDataCallBack, $0)
            }
        }()
        _configure()
    }
    private init(address: CFData, socket: CFSocket) {
        _address = address
        _socket = socket
        super.init()
    }
    private convenience init(address: String, port: UInt16, backType: CFSocketCallBackType = .dataCallBack) {
        self.init(address: {
            let size = MemoryLayout<sockaddr_in>.size
            var addr4 = sockaddr_in()
            
            addr4.sin_len = .init(size)
            addr4.sin_family = .init(AF_INET)
            addr4.sin_port = .init(port.bigEndian) // htons
            addr4.sin_addr.s_addr = inet_addr(address)
            //addr4.sin_addr.s_addr = htonl(INADDR_ANY);
            
            return withUnsafePointer(to: &addr4) {
                return $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                    return CFDataCreate(kCFAllocatorDefault, $0, size)
                }
            }
        }(), backType: backType)
    }
    deinit {
        // Remove socket source for run loop.
        _source.map {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), $0, CFRunLoopMode.commonModes)
        }
    }
    
    fileprivate func _configure() {
        // Create socket souce.
        _source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0)
        
        // Add socket source to run loop.
        _source.map {
            CFRunLoopAddSource(CFRunLoopGetMain(), $0, .commonModes)
        }
    }
    
    fileprivate func _recive(_ socket: CFSocket, address: CFData, data: Data?) {
        let client = Shared(address: address, socket: socket)

        _respond?(client, _decode(data))
        
        let respondObject = client._respondData ?? ""
        let _ = try? _SharedDataSend(socket, to: address as Data, data: _encode(respondObject))
    }
    
    fileprivate func _encode(_ value: Any?) -> Data {
        return value.map {
            return NSKeyedArchiver.archivedData(withRootObject: $0)
         } ?? Data()
    }
    fileprivate func _decode(_ data: Data?) -> Any? {
        return data.flatMap {
            return NSKeyedUnarchiver.unarchiveObject(with: $0)
        }
    }
    
    var address: Data {
        return _address as Data
    }

    private var _address: CFData
    private var _socket: CFSocket!
    private var _source: CFRunLoopSource?
    
    private var _respondData: Any?

    private var _respond: ((Shared, Any?) -> Void)?
}

private func _SharedDataCallBack(_ socket: CFSocket?, type: CFSocketCallBackType, address: CFData?, data: UnsafeRawPointer?, context: UnsafeMutableRawPointer?) {
    guard let socket = socket, let address = address, let context = context else {
        return
    }
    return Unmanaged<Shared>.fromOpaque(context).takeUnretainedValue()._recive(socket, address: address, data: data.map {
        return Unmanaged<CFData>.fromOpaque($0).takeUnretainedValue() as Data
    })
}

private func _SharedDataSend(_ socket: CFSocket, to address: Data, data: Data, timeout: TimeInterval = -1) throws {
    let error = CFSocketSendData(socket, address as CFData, data as CFData, .init(timeout))
    if error != .success {
        throw NSError(domain: "socket", code: error.rawValue, userInfo: nil)
    }
}
private func _SharedDataRecv(_ socket: CFSocket) throws -> Data {
    
    let ptr = UnsafeMutableRawPointer.allocate(bytes: 1024, alignedTo: 0)
    let data = NSMutableData()
    
    while true {
        let len = recv(CFSocketGetNative(socket), ptr, 1024, 0)
        if len < 0 {
            throw NSError(domain: "socket", code: -1, userInfo: nil)
        }
        data.append(ptr, length: len)
        if len != 1024 {
            break
        }
    }

    return data as Data
}


