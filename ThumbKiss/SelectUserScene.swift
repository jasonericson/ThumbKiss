//
//  SelectUserScene.swift
//  ThumbKiss
//
//  Created by Jason Ericson on 6/25/22.
//

import Foundation
import SpriteKit

class SelectUserScene: SKScene {
    func saveUser(user: String) {
        guard user == "w" || user == "j" else { return }
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("user.txt")
            
            do {
                try user.write(to: fileURL, atomically: true, encoding: .ascii)
            } catch {
                print("Could not print to file: \(error)")
            }
        }
        
        ConnectionManager.instance.user = user
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            print("A touch happened")
            
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            
            var user = ""
            if touchedNode.name == "WandaNode" {
                print("Picked Wanda")
                user = "w"
            } else if touchedNode.name == "JasonNode"{
                print("Picked Jason")
                user = "j"
            }
            
            if user == "w" || user == "j" {
                saveUser(user: user)
                if let connectScene = ConnectScene(fileNamed: "ConnectScene") {
                    self.scene?.view?.presentScene(connectScene)
                }
            }
        }
    }
}
