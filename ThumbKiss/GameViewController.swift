//
//  GameViewController.swift
//  ThumbKiss
//
//  Created by Jason Ericson on 4/13/22.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var user = ""
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("user.txt")
            
            do {
                user = try String(contentsOf: fileURL, encoding: .ascii)
            } catch {
                print("Couldn't open file: \(error)")
            }
        }
        
        if let view = self.view as! SKView? {
            if user == "w" || user == "j" {
                ConnectionManager.instance.user = user
                if let connectScene = SKScene(fileNamed: "ConnectScene") {
                    connectScene.scaleMode = .aspectFill
                    view.presentScene(connectScene)
                }
            } else {
                if let selectUserScene = SelectUserScene(fileNamed: "SelectUserScene") {
                    selectUserScene.scaleMode = .aspectFill
                    view.presentScene(selectUserScene)
                }
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
