/*
 * Copyright 2015 shrtlist.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import MultipeerConnectivity

// Delegate method for SessionController
protocol SessionControllerDelegate{
    // Multipeer Connectivity session changed state - connecting, connected and disconnected peers changed
    func sessionDidChangeState()
}

/*!
 @class SessionController
 @abstract
 A SessionController creates the MCSession that peers will be invited/join
 into, as well as creating service advertisers and browsers.
 
 MCSessionDelegate calls occur on a private operation queue. If your app
 needs to perform an action on a particular run loop or operation queue,
 its delegate method should explicitly dispatch or schedule that work
 */

class SessionController: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    // MARK: Public properties
    
    func sess() -> MCSession {
        return session;
    }
    
    var connectedPeers: [MCPeerID] {
        get {
            return session.connectedPeers
        }
    }
    
    var connectingPeers: [MCPeerID] {
        get {
            return connectingPeersDictionary.allValues as! [MCPeerID]
        }
    }
    
    var disconnectedPeers: [MCPeerID] {
        get {
            return disconnectedPeersDictionary.allValues as! [MCPeerID]
        }
    }
    
    var displayName: NSString {
        get {
            return session.myPeerID.displayName as NSString
        }
    }
    
    var delegate: SessionControllerDelegate?
    
    // MARK: Private properties
    
    fileprivate let peerID = MCPeerID(displayName: UIDevice.current.name)
    
    fileprivate lazy var session: MCSession = {
        let session = MCSession(peer: self.peerID)
        session.delegate = self
        return session
    }()
    
    fileprivate var serviceAdvertiser: MCNearbyServiceAdvertiser
    fileprivate var serviceBrowser: MCNearbyServiceBrowser
    
    // Connected peers are stored in the MCSession
    // Manually track connecting and disconnected peers
    fileprivate var connectingPeersDictionary = NSMutableDictionary()
    fileprivate var disconnectedPeersDictionary = NSMutableDictionary()
    
    // MARK: Initializer
    
    override init() {
        let kMCSessionServiceType = "mcsessionp2p"
        
        // Create the service advertiser
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: kMCSessionServiceType)
        
        // Create the service browser
        serviceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: kMCSessionServiceType)
        
        super.init()
        
        startServices()
    }
    
    // MARK: Deinitialization
    
    deinit {
        stopServices()
        
        session.disconnect()
        
        // Nil out delegate
        session.delegate = nil
    }
    
    // MARK: Services start / stop
    
    func startServices() {
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
        
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    func stopServices() {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceAdvertiser.delegate = nil
        
        serviceBrowser.stopBrowsingForPeers()
        serviceBrowser.delegate = nil
    }
    
    // MARK: MCSessionDelegate protocol conformance
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let displayName = peerID.displayName
        
        print("%@ [%@] %@", #function, displayName, MCSession.stringForPeerConnectionState(state))
        
        switch state {
        case .connecting:
            connectingPeersDictionary.setObject(peerID, forKey: displayName as NSCopying)
            disconnectedPeersDictionary.removeObject(forKey: displayName)
            
        case .connected:
            connectingPeersDictionary.removeObject(forKey: displayName)
            disconnectedPeersDictionary.removeObject(forKey: displayName)
                        
        case .notConnected:
            connectingPeersDictionary.removeObject(forKey: displayName)
            disconnectedPeersDictionary.setObject(peerID, forKey: displayName as NSCopying)
        }
            
        delegate?.sessionDidChangeState()

        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("RECIEVED DATA!!")
        
        let myString = "hello world" as NSString
        let myNSData =  myString.data(using: String.Encoding.utf8.rawValue)
        
        let rString : NSString = NSString(data: myNSData!, encoding: String.Encoding.utf8.rawValue)!
        let output = rString as String
        print("output: \(output)")
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("%@ %@ from [%@] with progress [%@]", #function, resourceName, peerID.displayName, progress)
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        // If error is not nil something went wrong
        if (error != nil) {
            print("%@ Error %@ from [%@]", #function, error!, peerID.displayName)
        }
        else {
            print("%@ %@ from [%@]", #function, resourceName, peerID.displayName)
        }
    }
    
    // Streaming API not utilized in this sample code
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("%@ %@ from [%@]", #function, streamName, peerID.displayName)
    }
    
    // MARK: MCNearbyServiceBrowserDelegate protocol conformance
    
    // Found a nearby advertising peer
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        let remotePeerName = peerID.displayName
        
        let myPeerID = session.myPeerID
        
        let shouldInvite = (myPeerID.displayName.compare(remotePeerName) == .orderedDescending)
        
        if (shouldInvite) {
            print("%@ Inviting [%@]", #function, remotePeerName)
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30.0)
        }
        else {
            print("%@ Not inviting [%@]", #function, remotePeerName)
        }
        
        delegate?.sessionDidChangeState()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("%@ lostPeer [%@]", #function, peerID.displayName)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("%@ %@", #function, error)
    }
    
    // MARK: MCNearbyServiceAdvertiserDelegate protocol conformance
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("%@ Accepting invitation from [%@]", #function, peerID.displayName)
        
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("%@ %@", #function, error)
    }
    
}
