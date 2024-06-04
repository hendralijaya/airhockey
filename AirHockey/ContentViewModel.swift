//
//  ContentViewModel.swift
//  AirHockey
//
//  Created by hendra on 02/06/24.
//

import Foundation
import MultipeerConnectivity
import Combine

enum Mallet {
    case red
    case blue
}

class ContentViewModel: NSObject, ObservableObject, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {
    private let serviceType = "air-hockey"
    private let peerId: MCPeerID
    private var peerSession: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    public var browser: MCBrowserViewController?
    
    @Published var gameState: GameState?
    @Published var isConnected = false
    @Published var showBrowser = false
    @Published var localMallet: Mallet = .red
    
    override init() {
        self.peerId = MCPeerID(displayName: UIDevice.current.name)
        self.peerSession = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: nil, serviceType: serviceType)
        super.init()
        self.peerSession.delegate = self
        self.advertiser.delegate = self
        self.gameState = GameState(
            puckPosition: CGPoint(x: 150, y: 250),
            puckVelocity: CGVector(dx: 5, dy: 5),
            mallet1Position: CGPoint(x: 150, y: 450),
            mallet2Position: CGPoint(x: 150, y: 50),
            scorePlayer1: 0,
            scorePlayer2: 0,
            controlledBy: peerId.displayName
        )
    }
    
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
    }
    
    func startBrowsing() {
        self.browser = MCBrowserViewController(serviceType: serviceType, session: peerSession)
        self.browser?.delegate = self
        self.showBrowser = true
    }
    
    func stopBrowsing() {
        self.showBrowser = false
        self.browser = nil
    }
    
    // MCSessionDelegate methods
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected to \(peerID.displayName)")
            DispatchQueue.main.async {
                self.isConnected = (state == .connected)
                if self.isConnected {
                    self.gameState = GameState(puckPosition: .zero,puckVelocity: .zero, mallet1Position: .zero, mallet2Position: .zero, scorePlayer1: 0, scorePlayer2: 0, controlledBy: self.peerSession.myPeerID.displayName)
                    self.localMallet = self.peerId.displayName < peerID.displayName ? .red : .blue
                }
                self.stopAdvertising()
                self.stopBrowsing()
            }
        case .connecting:
            print("Connecting to \(peerID.displayName)")
        case .notConnected:
            print("Not connected to \(peerID.displayName)")
            DispatchQueue.main.async {
                self.isConnected = false
            }
        @unknown default:
            print("Unknown state for \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle receiving data
        if let receivedState = try? JSONDecoder().decode(GameState.self, from: data) {
            DispatchQueue.main.async {
                self.gameState = receivedState
            }
        }
    }
    
    // Other MCSessionDelegate methods (optional)
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    // MCBrowserViewControllerDelegate methods
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
        self.showBrowser = false
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
        self.showBrowser = false
    }
    
    // MCNearbyServiceAdvertiserDelegate methods
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to advertise: \(error.localizedDescription)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from \(peerID.displayName)")
        invitationHandler(true, self.peerSession)
    }
    
    
    func updateGameState(_ newState: GameState) {
        gameState = newState
        if let data = try? JSONEncoder().encode(newState) {
            do {
                try peerSession.send(data, toPeers: peerSession.connectedPeers, with: .reliable)
            } catch {
                print("Failed to send data: \(error.localizedDescription)")
            }
        }
    }
    
    func updateMalletPosition(_ position: CGPoint) {
        if localMallet == .red {
            gameState?.mallet1Position = position
        } else {
            gameState?.mallet2Position = position
        }
        updateGameState(gameState!)
    }
}
