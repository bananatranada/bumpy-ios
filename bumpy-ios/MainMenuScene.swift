//
//  MainMenuScene.swift
//  bumpy-ios
//
//  Created by Byung Kang on 7/12/15.
//  Copyright (c) 2015 Bumpy Sounds. All rights reserved.
//

import SpriteKit

class MainMenuScene: SKScene {
    override func didMoveToView(view: SKView) {
        
        let background = SKSpriteNode(imageNamed:"proto_background1")
        background.position = CGPoint(x:self.size.width/2, y:self.size.height/2)
        self.addChild(background)
        
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        sceneTapped()
    }
    
    
    
    
    
    
    
    
    
    func sceneTapped() {
        let myScene = GameScene(size:self.size)
        myScene.scaleMode = scaleMode
        let reveal = SKTransition.doorwayWithDuration(1.5)
        self.view?.presentScene(myScene)
    }
    
    
}
