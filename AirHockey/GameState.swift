//
//  GameState.swift
//  AirHockey
//
//  Created by hendra on 02/06/24.
//

import Foundation
import MultipeerConnectivity

struct GameState: Codable {
    var puckPosition: CGPoint
    var puckVelocity: CGVector
    var mallet1Position: CGPoint
    var mallet2Position: CGPoint
    var scorePlayer1: Int
    var scorePlayer2: Int
    var controlledBy: String
}


