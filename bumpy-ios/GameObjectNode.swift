//
//  GameObjectNode.swift
//  bumpy-ios
//
//  Created by Byung Kang on 7/13/15.
//  Copyright (c) 2015 Bumpy Sounds. All rights reserved.
//

import SpriteKit

struct CollisionCategoryBitmask {
    static let Player: UInt32 = 0x00
    static let Platform: UInt32 = 0x01
}

class PlatformNode: SKSpriteNode {
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(inageName: String) {
        self.init(imageNamed: inageName)
    }
    required init(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
    func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }
    
    func checkNodeRemoval(playerY: CGFloat) {
        if playerY > self.position.x + 1000.0 {
            self.removeFromParent()
            println("node removed")
        }
    }
}

//class PlatformNode : GameObjectNode {
//    init(name: String) {
//        let node = SKSpriteNode(imageNamed: "enemy")
//        super.init(imageNamed: name)
//    }
//    
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
