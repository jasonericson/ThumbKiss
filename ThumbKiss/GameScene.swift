//
//  GameScene.swift
//  ThumbKiss
//
//  Created by Jason Ericson on 4/13/22.
//

import SpriteKit
import GameplayKit
import Network

struct Packet: Codable {
    var id: String
    var listenPort: Int
    var pos: CGPoint
}

class GameScene: SKScene {
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    private var label : SKLabelNode?
    private var thisThumb : SKSpriteNode?
    private var otherThumb : SKSpriteNode?
    private var otherThumbNormalizedX = -1.0
    private var otherThumbNormalizedY = -1.0
    
    func queueReceiveMessage() {
        if let c = ConnectionManager.instance.sendConnection {
            c.receiveMessage { data, context, isComplete, error in
                if let unwrappedError = error {
                    print("Error: NWError received in \(#function) - \(unwrappedError)")
                    return
                }
                guard isComplete, let data = data else {
                    print("Error: Received nil Data with context - \(String(describing: context))")
                    return
                }
                
                do {
                    let p = try self.jsonDecoder.decode(Packet.self, from: data)
                    
                    self.otherThumbNormalizedX = p.pos.x
                    self.otherThumbNormalizedY = p.pos.y
                    #if DEBUG
                    print("Other thumb pos: (\(p.pos.x), \(p.pos.y)")
                    #endif
                } catch {
                    print("failed to decode data: \(data)")
                }
                
                self.queueReceiveMessage()
            }
        }
    }
    
    override func didMove(to view: SKView) {
        let w = (self.size.width + self.size.height) * 0.1
        
        self.thisThumb = SKSpriteNode.init(imageNamed: "thumbprint")
        
        if let thisThumb = self.thisThumb {
            thisThumb.color = .blue
            thisThumb.colorBlendFactor = 1.0
            thisThumb.size = CGSize.init(width: w, height: w * 1.2)
        }
        
        self.otherThumb = SKSpriteNode.init(imageNamed: "thumbprint")
        
        if let otherThumb = self.otherThumb {
            otherThumb.color = .red
            otherThumb.colorBlendFactor = 1.0
            otherThumb.size = CGSize.init(width: w, height: w * 1.2)
        }

        if let s = ConnectionManager.instance.sendConnection {
            let posNormalized = CGPoint(x: 0.5, y: 0.5)
            let dataPacket = Packet(id: ConnectionManager.instance.user, listenPort: Int(ConnectionManager.instance.listenPort.rawValue), pos: posNormalized)
            let jsonData = try! jsonEncoder.encode(dataPacket)
            s.send(content: jsonData, completion: .contentProcessed({ sendError in
                if let error = sendError {
                    print("Unable to process and send the data: \(error)")
                }
            }))
        }

        queueReceiveMessage()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        if let n = self.thisThumb {
            if n.parent == nil {
                self.addChild(n)
            }

            n.position = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        if let n = self.thisThumb {
            n.position = touch.location(in: self)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        
        guard touches.first != nil else {
            return
        }
        
        if let n = self.thisThumb {
            if n.parent != nil {
                self.removeChildren(in: [n])
            }
        }
    }
    
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if let c = ConnectionManager.instance.sendConnection {
            if let n = self.thisThumb {
                if n.parent != nil {
                    let screenSize = UIScreen.main.bounds
                    let posNormalized = CGPoint(x: n.position.x / screenSize.width + 0.5, y: n.position.y / screenSize.height + 0.5)
                    let dataPacket = Packet(id: ConnectionManager.instance.user, listenPort: 0, pos: posNormalized)
                    let jsonData = try! jsonEncoder.encode(dataPacket)
                    c.send(content: jsonData, completion: .contentProcessed({ sendError in
                        if let error = sendError {
                            print("Unable to process and send the data: \(error)")
                        }
                    }))
                } else {
                    let dataPacket = Packet(id: ConnectionManager.instance.user, listenPort: 0, pos: CGPoint(x: -1.0, y: -1.0))
                    let jsonData = try! jsonEncoder.encode(dataPacket)
                    c.send(content: jsonData, completion: .contentProcessed({ sendError in
                        if let error = sendError {
                            print("Unable to process and send the data: \(error)")
                        }
                    }))
                }
            }
        }

        if let o = self.otherThumb {
            if self.otherThumbNormalizedX >= 0.0 && self.otherThumbNormalizedX <= 1.0 && self.otherThumbNormalizedY >= 0.0 && self.otherThumbNormalizedY <= 1.0 {
                if o.parent == nil {
                    self.addChild(o)
                }
                
                let screenSize = UIScreen.main.bounds
                let pos = CGPoint(x: (self.otherThumbNormalizedX - 0.5) * screenSize.width, y: (self.otherThumbNormalizedY - 0.5) * screenSize.height)
                
                o.position = pos
            } else {
                if o.parent != nil {
                    self.removeChildren(in: [o])
                }
            }
        }
    }
}
