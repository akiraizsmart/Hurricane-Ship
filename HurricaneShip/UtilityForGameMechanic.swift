//
//  UtilityForGameMechanic.swift
//  HurricaneShip
//
//  Created by Alessandro Raiola on 15/05/2020.
//  Copyright © 2020 alessandroraiola. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit
import UIKit

struct PhysicsCategory {
    static let        None: UInt32 = 0                //0
    static let        Ship: UInt32 = 0b1              //1
    static let      Meteor: UInt32 = 0b10             //2
    static let       Guard: UInt32 = 0b100            //4
    static let   Increaser: UInt32 = 0b1000           //8
    static let   Decreaser: UInt32 = 0b10000          //16
    static let GoldPowerUp: UInt32 = 0b100000         //32
}

struct AnimationKeys {
    static let Blink = "Blink"
}

public func stopAnimationFor(_ sprite: SKSpriteNode, forKey: String) {
    sprite.removeAction(forKey: forKey)
}

public func setUpAnimationWithPrefix(_ prefix: String, start: Int, end: Int, timePerFrame: TimeInterval) -> SKAction {
    var textures: [SKTexture] = []
    
    for i in start...end {
        textures.append(SKTexture(imageNamed: "\(prefix)\(i)"))
    }
    
    return SKAction.animate(with: textures, timePerFrame: timePerFrame)
}
