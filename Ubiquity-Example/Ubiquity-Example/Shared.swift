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
        let shared = Shared(address: address as CFData)
        return shared
    }
    public static func connect(_ address: String, port: UInt16)  -> Shared {
        let shared = Shared(address: address, port: port)
        return shared
    }
    
    public func send(_ data: Any?) {
        CFSocketSendData(_socket, _address, _encode(data) as CFData, -1)
    }
    
    public func recive(_ closure: @escaping (Shared, Any?) -> Void) {
        _respond = closure
    }
    
    public func wait() {
        let version = _version
        while _version == version {
            RunLoop.current.run(until: .init(timeIntervalSinceNow: 0.1))
        }
    }
    
    private init(address: CFData) {
        _address = address
        super.init()
        _socket = {
            var context = CFSocketContext()
            
            context.version = 0
            context.info = Unmanaged.passUnretained(self).toOpaque()
            
            return withUnsafePointer(to: &context) {
                return CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, CFSocketCallBackType.dataCallBack.rawValue, _SharedDataCallBack, $0)
            }
        }()
        _configure()
    }
    private init(address: CFData, socket: CFSocket) {
        _address = address
        _socket = socket
        super.init()
    }
    private convenience init(address: String, port: UInt16) {
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
        }())
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
        
        // weak up
        _version += 1
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
    
    private var _version: Int = 0
    
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
