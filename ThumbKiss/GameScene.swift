//
//  GameScene.swift
//  ThumbKiss
//
//  Created by Jason Ericson on 4/13/22.
//

import SpriteKit
import CoreHaptics
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
    
    private var collidingWithOtherThumb = false
    
    private let hapticsEngine = try? CHHapticEngine()
    private var continuousPlayer : CHHapticPatternPlayer?
    private let singleTapPattern = try? CHHapticPattern(
        events: [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0,
                duration: 0.05)
        ],
        parameterCurves: [
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.6),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.05, value: 0.6)
                ],
                relativeTime: 0)
        ])
    
    private let continuousPattern = try? CHHapticPattern(
        events: [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [],
                relativeTime: 0,
                duration: 100)
        ],
        parameterCurves: [
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.1),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 4, value: 0.6)
                ],
                relativeTime: 0)
        ])
    
    private var holdTime : Float = 0.0
    private let maxHoldTime : Float = 4.0
    private var lastUpdateTime : TimeInterval = 0
    
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
        
        try? self.hapticsEngine?.start()
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
    
    func getSqDistance(_ lhs: CGPoint, _ rhs: CGPoint) -> Float {
        let x = lhs.x - rhs.x
        let y = lhs.y - rhs.y
        let dist = x * x + y * y
        
        return Float(dist)
    }
    
    func startCollision() {
        self.collidingWithOtherThumb = true
        
        guard let engine = self.hapticsEngine else { return }
        
        if let pattern = self.singleTapPattern {
            let player = try? engine.makeAdvancedPlayer(with: pattern)
            try? player?.start(atTime: 0)
        }
        
        if let pattern = self.continuousPattern {
            self.continuousPlayer = try? engine.makeAdvancedPlayer(with: pattern)
            try? self.continuousPlayer?.start(atTime: 0)
            // holdTime
        }
    }
    
    func continueCollision() {
        
    }
    
    func endCollisionWithKiss() {
        self.collidingWithOtherThumb = false
        
        try? self.continuousPlayer?.stop(atTime: 0)
        self.continuousPlayer = nil
        
        guard let engine = self.hapticsEngine else { return }
        
        let intensity = min(self.holdTime / self.maxHoldTime, 1.0)
        if let pattern = try? CHHapticPattern(
            events: [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ],
                    relativeTime: 0,
                    duration: 0.5)
            ],
            parameterCurves: [
                CHHapticParameterCurve(
                    parameterID: .hapticIntensityControl,
                    controlPoints: [
                        CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: intensity),
                        CHHapticParameterCurve.ControlPoint(relativeTime: 0.5, value: 0.0)
                    ],
                    relativeTime: 0)
            ])
        {
            let player = try? engine.makePlayer(with: pattern)
            try? player?.start(atTime: 0)
        }
        
        self.holdTime = 0
    }
    
    func cancelCollision() {
        self.collidingWithOtherThumb = false
        
        try? self.continuousPlayer?.stop(atTime: 0)
        self.continuousPlayer = nil
        
        self.holdTime = 0
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - self.lastUpdateTime
        self.lastUpdateTime = currentTime
        
        if self.continuousPlayer != nil {
            self.holdTime += Float(deltaTime)
        }
        
        guard let t = self.thisThumb, let o = self.otherThumb, let c = ConnectionManager.instance.sendConnection else { return }
        
        if t.parent != nil {
            let screenSize = UIScreen.main.bounds
            let posNormalized = CGPoint(x: t.position.x / screenSize.width + 0.5, y: t.position.y / screenSize.height + 0.5)
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
        
        if o.parent != nil && t.parent != nil {
            let collisionDistance: Float = 200.0
            if getSqDistance(t.position, o.position) < collisionDistance * collisionDistance {
                if !self.collidingWithOtherThumb {
                    startCollision()
                } else {
                    continueCollision()
                }
            } else {
                if self.collidingWithOtherThumb {
                    cancelCollision()
                }
            }
        } else if o.parent != nil || t.parent != nil {
            if self.collidingWithOtherThumb {
                endCollisionWithKiss()
            }
        }
    }
}
