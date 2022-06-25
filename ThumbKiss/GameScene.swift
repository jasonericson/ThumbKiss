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
    private var thisThumb : SKShapeNode?
    private var otherThumb : SKShapeNode?
    private var otherThumbNormalizedX = 0.0
    private var otherThumbNormalizedY = 0.0
    
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
                    print("Other thumb pos: (\(p.pos.x), \(p.pos.y)")
                } catch {
                    print("failed to decode data: \(data)")
                }
                
                self.queueReceiveMessage()
            }
        }
    }
    
    override func didMove(to view: SKView) {
        
//        // Get label node from scene and store it for use later
//        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
//        if let label = self.label {
//            label.alpha = 0.0
//            label.run(SKAction.fadeIn(withDuration: 2.0))
//        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        
        self.thisThumb = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
//        self.thisThumb = SKSpriteNode.init(fileNamed: "thumbprint.png")
        
        if let thisThumb = self.thisThumb {
//            thisThumb.color = .blue
//            thisThumb.colorBlendFactor = 1.0
            thisThumb.lineWidth = 2.5
            thisThumb.strokeColor = .blue
            thisThumb.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
//            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
//                                              SKAction.fadeOut(withDuration: 0.5),
//                                              SKAction.removeFromParent()]))
        }
        
        self.otherThumb = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
//        self.otherThumb = SKSpriteNode.init(fileNamed: "thumbprint.png")
        
        if let otherThumb = self.otherThumb {
//            otherThumb.color = .red
//            otherThumb.colorBlendFactor = 1.0
            otherThumb.lineWidth = 2.5
            otherThumb.strokeColor = .red
            otherThumb.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            
            self.addChild(otherThumb)
        }

        if let s = ConnectionManager.instance.sendConnection {
            let posNormalized = CGPoint(x: 0.5, y: 0.5)
            let dataPacket = Packet(id: "w", listenPort: Int(ConnectionManager.instance.listenPort.rawValue), pos: posNormalized)
            let jsonData = try! jsonEncoder.encode(dataPacket)
            s.send(content: jsonData, completion: .contentProcessed({ sendError in
                if let error = sendError {
                    print("Unable to process and send the data: \(error)")
                }
            }))
        }

        queueReceiveMessage()
    }
    
    
//    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.green
//            self.addChild(n)
//        }
//    }
//
//    func touchMoved(toPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.blue
//            self.addChild(n)
//        }
//    }
//
//    func touchUp(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.red
//            self.addChild(n)
//        }
//    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
        
        if let n = self.thisThumb {
            if self.children.contains(n) == false {
                self.addChild(n)
            }

            n.position = touch.location(in: self)
        }
        
//        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        if let n = self.thisThumb {
            n.position = touch.location(in: self)
        }
//        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        
        guard touches.first != nil else {
            return
        }
        
        if let n = self.thisThumb {
            if self.children.contains(n) {
                self.removeChildren(in: [n])
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if let c = ConnectionManager.instance.sendConnection {
            if let n = self.thisThumb {
                if n.parent != nil {
                    let screenSize = UIScreen.main.bounds
                    let posNormalized = CGPoint(x: n.position.x / screenSize.width + 0.5, y: n.position.y / screenSize.height + 0.5)
                    let dataPacket = Packet(id: "w", listenPort: 0, pos: posNormalized)
                    let jsonData = try! jsonEncoder.encode(dataPacket)
                    c.send(content: jsonData, completion: .contentProcessed({ sendError in
                        if let error = sendError {
                            print("Unable to process and send the data: \(error)")
                        }
                    }))
                } else {
                    let dataPacket = Packet(id: "w", listenPort: 0, pos: CGPoint(x: -1.0, y: -1.0))
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
