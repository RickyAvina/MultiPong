//
//  GameScene.swift
//  MultiPong
//
//  Created by Maricela Avina on 12/10/16.
//  Copyright © 2016 InternTeam. All rights reserved.
//

import SpriteKit
import GameplayKit
import MultipeerConnectivity

class GameScene: SKScene, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    var ball = SKSpriteNode()
    var enemy = SKSpriteNode()
    var main = SKSpriteNode()
    
    var topLabel = SKLabelNode()
    var bottomLabel = SKLabelNode()
    
    var startButton : SKNode! = nil
    var gameStarted : Bool = false
    
    var score = [Int]()
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    var leftWall = SKSpriteNode()
    var rightWall = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        startButton = SKSpriteNode(color: SKColor.blue, size: CGSize(width: 100, height: 44))
        startButton.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        self.addChild(startButton)
        
        ball = self.childNode(withName: "ball") as! SKSpriteNode
        enemy = self.childNode(withName: "enemy") as! SKSpriteNode
        main = self.childNode(withName: "main") as! SKSpriteNode
        
        topLabel = self.childNode(withName: "topLabel") as! SKLabelNode
        bottomLabel = self.childNode(withName: "bottomLabel") as! SKLabelNode
        
        
        leftWall = self.childNode(withName: "leftWall") as! SKSpriteNode
        rightWall = self.childNode(withName: "rightWall") as! SKSpriteNode
        
        ball.isHidden = true
        enemy.isHidden = true
        main.isHidden = true
        topLabel.isHidden = true
        bottomLabel.isHidden = true
        
        
    }
    
    func startGame() {
        
        if mcSession.connectedPeers.count != 1 { // should be 1
            showConnectionPrompt()
        } else {
            
            ball.isHidden = false
         //   enemy.isHidden = false
            main.isHidden = false
            topLabel.isHidden = false
            bottomLabel.isHidden = false
            startButton.isHidden = true
            
            ball.physicsBody?.applyImpulse(CGVector(dx: 20, dy: 20)) // give it initial push
           
            
          //  let border = SKPhysicsBody(edgeLoopFrom: self.frame)
          //  border.friction = 0
          //  border.restitution = 1
          //  self.physicsBody = border
            
            score = [0,0]   // myScore, enemyScore
            topLabel.text = "\(score[1])"
            bottomLabel.text = "\(score[0])"
        }
    }
    
    func addScore(playerWhoWon : SKSpriteNode){
        
        ball.position = CGPoint(x: 0, y: 0)
        ball.physicsBody?.velocity = CGVector(dx: 0, dy: 0)     // remove all forces
        
        if playerWhoWon == main {
            score[0]+=1
            ball.physicsBody?.applyImpulse(CGVector(dx: 20, dy: 20))
        } else if playerWhoWon == enemy {
            score[1]+=1
            ball.physicsBody?.applyImpulse(CGVector(dx: -20, dy: -20))
        }
        
        topLabel.text = "\(score[1])"
        bottomLabel.text = "\(score[0])"
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self) // location of finger
            
            if startButton.contains(location){
                startGame()
            }
            
            main.run(SKAction.moveTo(x: location.x, duration: 0.2))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self) // location of finger
            main.run(SKAction.moveTo(x: location.x, duration: 0.2))
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        enemy.run(SKAction.moveTo(x: ball.position.x + 5000, duration: 0.4))
        
        if ball.position.y <= main.position.y - 20 {
            addScore(playerWhoWon: enemy)
            
        } else if ball.position.y >= self.frame.height - 15 {
          //  addScore(playerWhoWon: main)
            do {
                let pointToSend : CGPoint = ball.position
                let pointData = NSStringFromCGPoint(pointToSend).data(using: .utf8)
            try mcSession.send(pointData! as Data, toPeers: mcSession.connectedPeers, with: .unreliable)
            } catch let error as NSError{
                let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                let currentViewController :
                    UIViewController=UIApplication.shared.keyWindow!.rootViewController!
                currentViewController.present(ac, animated: true, completion: nil)
            }

        }
        
    }
    
    func showConnectionPrompt(){
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let currentViewController :
            UIViewController=UIApplication.shared.keyWindow!.rootViewController!
        currentViewController.present(ac, animated: true, completion: nil)
    }
    
    func startHosting(action: UIAlertAction){
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "it-pong", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    func joinSession(action: UIAlertAction){
        let mcBrowser = MCBrowserViewController(serviceType: "it-pong", session: mcSession)
        mcBrowser.delegate = self
        
        let vc = self.view?.window!.rootViewController!
        vc?.present(mcBrowser, animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
            
        case .connecting:
            print("Connecting: \(peerID.displayName)")
            
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let pointString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        let ballPos = CGPointFromString(pointString as! String)
        
        print("Ball Position: (\(ballPos.x), \(ballPos.y))")
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)

    }
    
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
      browserViewController.dismiss(animated: true, completion: nil)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
}
