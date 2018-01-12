//
//  XPCDebugger.swift
//  Ubiquity
//
//  Created by sagesse on 10/01/2018.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import UIKit

///
/// A XPC Debugger
///
public class XPCDebugger {
    
    /// The command execution results.
    public enum Result {
        /// An error occurred when the command was executed.
        case error(String)
        /// The command executed success on remote server.
        case success(Any?)
        /// The command no response on remote server.
        case undefined
        
        /// Get the data, if execution successfully.
        var data: Any? {
            switch self {
            case .success(let d): return d
            default: return nil
            }
        }
        /// Get the error, if execution failure.
        var error: String? {
            switch self {
            case .error(let e): return e
            default: return nil
            }
        }
    }
    
    /// A shared debugger.
    public static var shared: XPCDebugger = XPCDebugger()
    
    /// Create a debugger.
    public init() {
        // Create two full-duplex socket.
        let sender = socket(PF_INET, SOCK_DGRAM, 0)
        let receiver = socket(PF_INET, SOCK_DGRAM, 0)
        
        // Bind a random port for socket.
        var addr = sockaddr_in()
        var addrlen = socklen_t(MemoryLayout.size(ofValue: addr))
        
        addr.sin_family = .init(AF_INET)
        addr.sin_addr.s_addr = INADDR_ANY
        addr.sin_port = 0
        
        withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(receiver, $0, addrlen)
                Darwin.getsockname(receiver, $0, &addrlen)
            }
        }
        
        self.sender = sender
        self.receiver = receiver
        
        // Read the current listen port of socket.
        self.from = "debugger://127.0.0.1:\(addr.sin_port.bigEndian)"
        
        // Create a new thread to handle the remote commands.
        DispatchQueue(label: "dispatch-xpc-debugger").async { [weak self] in
            while let receiver = self?.receiver {
                XPCDebugger.recvfrom(receiver) { pack in
                    XPCDebugger.unwrap(pack.data) { unpack in
                        // If the self is nil, this suggests the debuger has been released.
                        guard let debugger = self else {
                            return
                        }
                        XPCDebugger.prcoess(debugger, pack: unpack) {
                            XPCDebugger.wrap($0) {
                                XPCDebugger.sendto(receiver, addr: pack.addr, data: $0)
                            }
                        }
                    }
                }
            }
        }
    }
    deinit {
        close(sender)
        close(receiver)
    }
    
    /// The address of the remote connection.
    public let from: String
    
    /// Provides a handler called on cmd triggered.
    public func on(_ cmd: String, closure: @escaping ((parameter: Any?, complete: (Any?) -> ())) -> ()) {
        self.handlers[cmd] = closure
    }
    
    /// Remove a handler on cmd triggered.
    public func remove(_ cmd: String) {
        self.handlers.removeValue(forKey: cmd)
    }

    /// Send a command to specified server.
    @discardableResult
    public func emit(_ cmd: String, _ args: Any? = nil) -> Result {
        // If the to is nil, the client not connected.
        guard let to = to else {
            return .error("The client socket has been disconnected!")
        }
        var result = Result.undefined
        
        XPCDebugger.wrap((cmd, args)) {
            XPCDebugger.sendto(sender, addr: to, data: $0)
            XPCDebugger.recvfrom(sender) { pack in
                XPCDebugger.unwrap(pack.data) { unpack in
                    if unpack.cmd == "success" {
                        result = .success(unpack.args)
                    }
                    if unpack.cmd == "error" {
                        result = .error(args as? String ?? "An unknown error!")
                    }
                }
            }
        }
        
        return result
    }
    /// Connect to specified server.
    public func connect(to addr: String) {
        // Send init command to server.
        to = addr
        emit("api-init", from)
    }
    
    fileprivate static func prcoess(_ debugger: XPCDebugger, pack: (cmd: String, args: Any?), transform: ((cmd: String, args: Any?)) -> ()) {
        // The address must be recorded before handler, otherwise the command can not be sent to execption.
        if pack.cmd == "api-init" {
            debugger.to = pack.args as? String
        }
        var result: Any?
        
        debugger.handlers[pack.cmd]?((pack.args, {
            result = $0
        }))
        
        transform(("success", result))
    }
    fileprivate static func convert(_ addr: inout sockaddr_in) -> UnsafeMutablePointer<sockaddr> {
        return withUnsafeMutablePointer(to: &addr) {
            return $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                return $0
            }
        }
    }
    
    fileprivate static func sendto(_ sock: Int32, addr: String, data: Data) {
        // Parsing the address information.
        guard let url = URL(string: addr), let host = url.host, let port = url.port else {
            return
        }
        
        // Generate the address information.
        var addr = sockaddr_in()
        var count = data.count
        
        addr.sin_family = .init(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = inet_addr(host)

        let ptr = (data as NSData).bytes
        let size = 1024
        let countlen = MemoryLayout.size(ofValue: count)
        
        let addrlen = socklen_t(MemoryLayout.size(ofValue: addr))
        
        Darwin.sendto(sock, &count, countlen, 0, convert(&addr), addrlen)
        for i in (0 ... (count - 1) / size) {
            Darwin.sendto(sock, ptr.advanced(by: i * size), min(count - i * size, size), 0, convert(&addr), addrlen)
        }
    }
    fileprivate static func recvfrom(_ sock: Int32, transform: ((addr: String, data: Data)) -> ()) {
        // Generate the address information.
        var addr = sockaddr_in()
        var addrlen = socklen_t(MemoryLayout.size(ofValue: addr))
        var count = Int.max
        var data = Data()
        
        let size = 1024
        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        let countlen = MemoryLayout.size(ofValue: count)
        
        repeat {
            let nret = Darwin.recvfrom(sock, buf, min(count - data.count, size), 0, convert(&addr), &addrlen)
            guard nret >= 0 else {
                // socket execption.
                return
            }

            guard count == .max else {
                // Merge a package.
                data.append(buf, count: nret)
                continue
            }
            
            // Merge in addition to the length of package.
            data.append(buf.advanced(by: countlen), count: nret - countlen)
            buf.withMemoryRebound(to: Int.self, capacity: 1) {
               count = $0.move()
            }
            
        } while data.count < count
        
        // To next step to process.
        transform(("debugger://127.0.0.1:\(addr.sin_port.bigEndian)", data))
    }
    
    fileprivate static func wrap(_ pack: (cmd: String, args: Any?), transform: (Data) -> ()) {
        // Encode object to data.
        transform(NSKeyedArchiver.archivedData(withRootObject: [pack.cmd, pack.args]))
    }
    fileprivate static func unwrap(_ data: Data, transform: ((cmd: String, args: Any?)) -> ()) {
        // Decode data to object.
        NSKeyedUnarchiver.unarchiveObject(with: data).map {
            ($0 as? Array<Any?>).map {
                // Matching the array element type.
                guard let cmd = $0.first as? String, let args = $0.last else {
                    return
                }
                transform((cmd, args))
            }
        }
    }
    
    fileprivate let sender: Int32
    fileprivate let receiver: Int32

    fileprivate var to: String?
    fileprivate var handlers: [String:(((parameter: Any?, complete: (Any?) -> ())) -> ())] = [:]
}
