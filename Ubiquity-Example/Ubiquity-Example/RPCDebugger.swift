//
//  RPCDebugger.swift
//  Ubiquity
//
//  Created by sagesse on 10/01/2018.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import UIKit

///
/// RPC Debugger Server & Endpoint
///
public class RPCDebugger {
    
    /// The server connect event.
    public enum Event: Int {
        /// A endpoint has been connected.
        case connected
        /// A endpoint has been disconnected.
        case disconnected
    }
    
    /// The command execution results.
    public enum Result {
        /// An error occurred when the command was executed.
        case error(String)
        /// The command executed success on remote server.
        case success(Any?)
        /// The command no response on remote server.
        case undefined
        
        /// Mapping..
        public func map(_ closure: ((parameters: Any?, error: String?)) -> ()) {
            switch self {
            case .error(let e):
                closure((nil, e))
                
            case .success(let p):
                closure((p, nil))
                
            case .undefined:
                closure((nil, nil))
            }
        }
    }
    
    
    /// The address of the current `RPC Debugger Server`.
    public var port: Int = 0
    
    /// Create a `RPC Debugger Server`.
    public static var shared: RPCDebugger = RPCDebugger()
    
    
    /// Provides a handler called on cmd triggered.
    public func on(_ cmd: String, closure: @escaping ((parameter: Any?, complete: (Any?) -> ())) -> ()) {
        _handlers[cmd] = closure
    }
    
    /// Remove a handler on cmd triggered.
    public func remove(_ cmd: String) {
        _handlers.removeValue(forKey: cmd)
    }
    
    /// Send a command to `RPC Debugger Server`.
    @discardableResult
    public func emit(_ cmd: String, _ arg: Any? = nil) -> Result {
        guard let socket = _socket else {
            return .error("The socket create failure!")
        }
        // The client whether it has been connected
        guard let address = _endport else {
            return .error("The client socket has been disconnected!")
        }
        // The api-init command is a reservation command.
        guard cmd != "api-init" else {
            return .error("The api-init command is a reservation command!")
        }
        do {
            // Sending commands to the endpoint.
            try _send(socket, to: address, data: _wrap(cmd, arg))
            
            // A command must wait for a return value after a command is sent.
            guard let data = _unwrap(try _receive(socket)) else {
                return .error(" Data parsing failure ")
            }
            
            switch data.cmd {
            case "success":
                return .success(data.arg)
                
            case "error":
                return .error(data.arg as? String ?? "An unknown error!")
                
            default:
                return .undefined
            }
            
        } catch {
            // An unknown error occurred, usually socket closed.
            return .error("An unknown error!")
        }
    }
    
    /// Create a `RPC Debugger Server` to connect the specified server.
    public func connect(to address: String) {
        _socket.map {
            let addr4 = _sockaddr(address)
            _ = try? _send($0, to: addr4, data: _wrap("api-init", nil))
            _endport = addr4
        }
    }
    
    /// Craete a empty `RPC Debugger Server`
    private init() {
        // Bind a port of socket.
        _bind()
    }
    deinit {
        // Unbind a port of socket.
        _unbind()
    }
    
    private func _bind() {
        
        let addr = _sockaddr("debugger://127.0.0.1:\(port)") as Data
        let socket = _sockudp()
        let event = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        
        // Bind a socket.
        addr.withUnsafeBytes {
            _ = bind(CFSocketGetNative(socket), $0, .init(addr.count))
        }
        
        // Read current port.
        (CFSocketCopyAddress(socket) as Data).withUnsafeBytes { (addr4: UnsafePointer<sockaddr_in>) in
            port = .init(addr4.pointee.sin_port)
        }
        
        // Add to runloop.
        CFRunLoopAddSource(CFRunLoopGetMain(), event, .commonModes)
        
        // Save
        _event = event
        _socket = socket
    }
    private func _unbind() {
        _socket.map {
            _ = close(CFSocketGetNative($0))
        }
        _event.map {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), $0, CFRunLoopMode.commonModes)
        }
    }
    
    fileprivate func receive(_ socket: CFSocket, address: CFData, data: Data?) {
        // Ignore him when data parsing fails.
        guard let data = data.flatMap({ _unwrap($0) }) else {
            return
        }
        _task(socket, address: address, data: data)
    }

    fileprivate func _task(_ socket: CFSocket, address: CFData, data: (cmd: String, arg: Any?)) {
        
        // The address must be recorded before handler, otherwise the command can not be sent to execption.
        if data.cmd == "api-init" {
            _endport = address
        }
        
        // Record the response results.
        var pack: Any??
        
        // Invocation of user defined handler.
        _handlers[data.cmd]?((data.arg, {
            pack = $0
        }))
        
        // The api-init command does not need to respond.
        if data.cmd == "api-init" {
            return
        }
        
        // The api-hook when user does not handle, execute the default implementation.
        if data.cmd == "api-hook", pack == nil {
            (data.arg as? String).map {
                _hook($0)
                pack = nil
            }
        }
        
        // The api-forward when user does not handle, execute the default implementation.
        if data.cmd == "api-forward", pack == nil {
            pack = nil
        }

        if let result = pack {
            // The command process suc  cess.
            _ = try? _send(socket, to: address, data: _wrap("success", result))
        } else {
            // The command failed to respond
            _ = try? _send(socket, to: address, data: _wrap("undefined", nil))
        }
    }
    
    private func _sockaddr(_ address: String) -> CFData {
        
        let url = URL(string: address)
        let size = MemoryLayout<sockaddr_in>.size
        
        var addr4 = sockaddr_in()
        
        addr4.sin_len = .init(size)
        addr4.sin_family = .init(AF_INET)
        addr4.sin_port = .init(url?.port ?? 0)
        addr4.sin_addr.s_addr = INADDR_ANY // htonl
        
        url?.host.map {
            addr4.sin_addr.s_addr = inet_addr($0)
        }
        
        return withUnsafePointer(to: &addr4) {
            return $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                return CFDataCreate(kCFAllocatorDefault, $0, size)
            }
        }
    }
    private func _sockudp() -> CFSocket {
        var context = CFSocketContext()
        
        context.version = 0
        context.info = Unmanaged.passUnretained(self).toOpaque()
        
        return withUnsafePointer(to: &context) {
            return CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, CFSocketCallBackType.dataCallBack.rawValue, _callback, $0)
        }
    }
    
    private func _wrap(_ cmd: String, _ arg: Any?) -> Data {
        // Encode object to data.
        return NSKeyedArchiver.archivedData(withRootObject: [cmd, arg])
    }
    private func _unwrap(_ data: Data) -> (cmd: String, arg: Any?)? {
        // Decode data to object.
        return NSKeyedUnarchiver.unarchiveObject(with: data).flatMap {
            return ($0 as? Array<Any?>).flatMap {
                // Matching the array element type.
                guard let cmd = $0.first as? String, let arg = $0.last else {
                    return nil
                }
                return (cmd, arg)
            }
        }
    }
    
    private func _hook(_ matching: String) {
    }
    private func _forward(_ parameters: Any?) {
    }
    
    private var _event: CFRunLoopSource?
    private var _socket: CFSocket?
    private var _endport: CFData?
    
    private var _handlers: [String:(((parameter: Any?, complete: (Any?) -> ())) -> ())] = [:]
}

private func _callback(_ socket: CFSocket?, type: CFSocketCallBackType, address: CFData?, data: UnsafeRawPointer?, context: UnsafeMutableRawPointer?) {
    guard let socket = socket, let address = address, let context = context else {
        return
    }
    return Unmanaged<RPCDebugger>.fromOpaque(context).takeUnretainedValue().receive(socket, address: address, data: data.map {
        return Unmanaged<CFData>.fromOpaque($0).takeUnretainedValue() as Data
    })
}

private func _send(_ socket: CFSocket, to address: CFData, data: Data, timeout: TimeInterval = -1) throws {
    let error = CFSocketSendData(socket, address, data as CFData, .init(timeout))
    if error != .success {
        throw NSError(domain: "socket", code: error.rawValue, userInfo: nil)
    }
}
private func _receive(_ socket: CFSocket) throws -> Data {
    
    let ptr = UnsafeMutableRawPointer.allocate(bytes: 1024, alignedTo: 0)
    let data = NSMutableData()
    
    CFSocketDisableCallBacks(socket, CFSocketCallBackType.dataCallBack.rawValue)
    defer {
        CFSocketEnableCallBacks(socket, CFSocketCallBackType.dataCallBack.rawValue)
    }
    
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

// Network Hook
extension URLSession {
    
//    func debugger_hook_dataTaskWithURL(_ url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
//        return debugger_hook_dataTaskWithURL(url, completionHandler:completionHandler)
//    }
//
//    func debugger_hook_dataTaskWithRequest(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
//        return debugger_hook_dataTaskWithRequest(request, completionHandler:completionHandler)
//    }

}
