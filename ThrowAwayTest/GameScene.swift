//
//  GameScene.swift
//  ThrowAwayTest
//
//  Created by Maricela Avina on 12/26/16.
//  Copyright © 2016 InternTeam. All rights reserved.
//

import SpriteKit
import GameplayKit
import MultipeerConnectivity

class GameScene: SKScene, SessionControllerDelegate {
    
    let sessionController = SessionController()
    
    var square = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        sessionController.delegate = self
        square.size = CGSize(width: 80, height: 80)
        square.position = CGPoint(x: 0, y: 0)
        square.color = UIColor.blue
        self.addChild(square)
        square.isHidden = true;
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    deinit {
        // Nil out delegate
        sessionController.delegate = nil
    }
    
    func sessionDidChangeState() {
        if sessionController.connectedPeers.count > 0 {
            square.isHidden = false;
            
            do {
                let myString : NSString = "a" as NSString
                let myData = myString.data(using: String.Encoding.utf8.rawValue)
                
                try sessionController.sess().send(myData! as Data, toPeers: sessionController.connectedPeers, with: .reliable)
            } catch let error as NSError{
                let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                let currentViewController :
                    UIViewController=UIApplication.shared.keyWindow!.rootViewController!
                currentViewController.present(ac, animated: true, completion: nil)
            }

        }
        
    }
}
