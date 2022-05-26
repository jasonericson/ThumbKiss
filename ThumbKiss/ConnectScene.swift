//
//  ConnectScene.swift
//  ThumbKiss
//
//  Created by Jason Ericson on 5/23/22.
//

import Network
import SpriteKit

class ConnectScene: SKScene {
    var host: NWEndpoint.Host = "127.0.0.1"
    var port: NWEndpoint.Port = 1234
    
    override func didMove(to view: SKView) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if touchedNode.name == "ConnectNode" {
                ConnectionManager.instance.connection = NWConnection(host: host, port: port, using: .udp)
                
                ConnectionManager.instance.connection!.stateUpdateHandler = { (newState) in
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
                
                ConnectionManager.instance.connection!.viabilityUpdateHandler = { (isViable) in
                    if (isViable) {
                        if let gameScene = GameScene(fileNamed: "GameScene") {
                            self.scene?.view?.presentScene(gameScene)
                        }
                    } else {
                        NSLog("Connection is not viable")
                    }
                }
                
                ConnectionManager.instance.connection!.betterPathUpdateHandler = { (betterPathAvailable) in
                    if (betterPathAvailable) {
                        NSLog("A better path is availble")
                    } else {
                        NSLog("No better path is available")
                    }
                }
                
                ConnectionManager.instance.connection!.start(queue: .global())
            }
        }
    }
}
