//
//  ConnectionManager.swift
//  ThumbKiss
//
//  Created by Jason Ericson on 5/23/22.
//

import Foundation
import Network

class ConnectionManager {
    static let instance = ConnectionManager()
    
    let host: NWEndpoint.Host = "127.0.0.1"
    let port: NWEndpoint.Port = 1234
    let listenPort: NWEndpoint.Port = 1236
    
    var sendConnection : NWConnection?
//    var receiveConnection : NWConnection?
//    var listener : NWListener?
    
    private func startSingleConnection(connection: inout NWConnection?, viabilityUpdateHandler: ((_ isViable: Bool) -> Void)?) -> Bool {
        connection = NWConnection(host: host, port: port, using: .udp)
        
        connection!.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .preparing:
                NSLog("Entered state: preparing")
            case .ready:
                NSLog("Entered state: ready")
            case .setup:
                NSLog("Entered state: setup")
            case .cancelled:
                NSLog("Entered state: cancelled")
            case .waiting:
                NSLog("Entered state: waiting")
            case .failed:
                NSLog("Entered state: failed")
            default:
                NSLog("Entered an unknown state")
            }
        }
        
        connection!.betterPathUpdateHandler = { (betterPathAvailable) in
            if (betterPathAvailable) {
                NSLog("A better path is availble")
            } else {
                NSLog("No better path is available")
            }
        }
        
        connection!.viabilityUpdateHandler = viabilityUpdateHandler
        
        connection!.start(queue: .global())
        
        return true
    }
    
    public func startConnections(viabilityUpdateHandler: ((_ isViable: Bool) -> Void)?) -> Bool {
        guard startSingleConnection(connection: &self.sendConnection, viabilityUpdateHandler: viabilityUpdateHandler) else {
            return false
        }
        
//        self.listener = try! NWListener(using: .udp, on: self.listenPort)
//
//        self.listener!.stateUpdateHandler = { (newState) in
//            switch (newState) {
//            case .ready:
//                NSLog("Listener ready.")
//            case .failed(let error):
//                NSLog("Listener failure, error: \(error.localizedDescription)")
//            default:
//                break
//            }
//        }
//
//        self.listener!.newConnectionHandler = { (connection) in
//            self.receiveConnection = connection
//            self.receiveConnection!.viabilityUpdateHandler = viabilityUpdateHandler
//            self.receiveConnection!.start(queue: .global())
//        }
//
//        self.listener!.start(queue: .global())
        
        return true
    }
}
