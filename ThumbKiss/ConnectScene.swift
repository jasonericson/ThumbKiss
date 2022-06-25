//
//  ConnectScene.swift
//  ThumbKiss
//
//  Created by Jason Ericson on 5/23/22.
//

import Network
import SpriteKit

class ConnectScene: SKScene {
    let jsonEncoder = JSONEncoder()

    override func didMove(to view: SKView) {
        
    }
    
    func onConnectionViable() {
        if ConnectionManager.instance.sendConnection?.state == .ready {
//            if ConnectionManager.instance.receiveConnection?.state == .ready {
                if let gameScene = GameScene(fileNamed: "GameScene") {
                    self.scene?.view?.presentScene(gameScene)
                }
//            } else {
//                if let s = ConnectionManager.instance.sendConnection {
//                    let posNormalized = CGPoint(x: 0.5, y: 0.5)
//                    let dataPacket = Packet(id: "w", listenPort: 1235, pos: posNormalized)
//                    let jsonData = try! jsonEncoder.encode(dataPacket)
//                    s.send(content: jsonData, completion: .contentProcessed({ sendError in
//                        if let error = sendError {
//                            print("Unable to process and send the data: \(error)")
//                        }
//                    }))
//                }
//            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if touchedNode.name == "ConnectNode" {
                let viabilityUpdateHandler: ((_ isViable: Bool) -> Void)? = { (isViable) in
                    if (isViable) {
                        self.onConnectionViable()
                    } else {
                        NSLog("Connection is not viable")
                    }
                }
                
                ConnectionManager.instance.startConnections(viabilityUpdateHandler: viabilityUpdateHandler)
            }
        }
    }
}
