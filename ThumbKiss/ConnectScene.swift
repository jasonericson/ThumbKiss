//
//  ConnectScene.swift
//  ThumbKiss
//
//  Created by Jason Ericson on 5/23/22.
//

import SpriteKit

class ConnectScene: SKScene {
    override func didMove(to view: SKView) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            for touch in touches {
                let location = touch.location(in: self)
                let touchedNode = atPoint(location)
                if touchedNode.name == "ConnectNode" {
                    if let gameScene = SKScene(fileNamed: "GameScene") {
                        scene?.view?.presentScene(gameScene)
                    }
                }
            }
        }
}
