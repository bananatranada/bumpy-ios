//
//  GameScene.swift
//  bumpy-ios
//
//  Created by Byung Kang on 7/7/15.
//  Copyright (c) 2015 Bumpy Sounds. All rights reserved.
//

// double jump, glide, slow

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let playerNode: SKSpriteNode = SKSpriteNode(imageNamed: "ninja_pixel")
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 0
    var velocity = CGPointZero
    let playableRect: CGRect
    var lastTouchLocation: CGPoint?
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    let zombieAnimation: SKAction
//    let catCollisionSound: SKAction = SKAction.playSoundFileNamed(
//        "hitCat.wav", waitForCompletion: false)
//    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed(
//        "hitCatLady.wav", waitForCompletion: false)
    var invincible = true
    let catMovePointsPerSec:CGFloat = 480.0
    var lives = 5
    var gameOver = false
    var backgroundMovePointsPerSec: CGFloat = 1400.0
//    let backgroundMovePointsPerSec: CGFloat = 0
    
    let backgroundNode = SKNode()
    let midgroundNode = SKNode()
    let platformNode = SKNode()
    let foregroundNode = SKNode()
    let hudNode = SKNode()
    
    let playerDistanceSinceLastPlatform = 0.0
    
    let platformDistance = 600
    
    var tapBeganTime: NSTimeInterval = 0
    var totalContactTime: NSTimeInterval = 0
    var didStartContact = false
    var contactedPlatform = SKNode()
    var playerInAir = false
    var screenHeld = false
    var massChanged = false
    var secondJump = false
    
    var prevPlatform = SKNode()
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin,
            width: size.width,
            height: playableHeight)
        var textures:[SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        
        zombieAnimation = SKAction.repeatActionForever(
            SKAction.animateWithTextures(textures, timePerFrame: 0.1))
        
        super.init(size: size)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
//        playBackgroundMusic("backgroundMusic.mp3")
        backgroundNode.zPosition = -1
        platformNode.zPosition = 0
        addChild(backgroundNode)
        addChild(midgroundNode)
        addChild(platformNode)
        backgroundColor = SKColor.whiteColor()
        addChild(foregroundNode)
        
        for i in 0...1 {
            let background = createBackgroundNode()
            background.anchorPoint = CGPointZero
            background.position = CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = "background"
            backgroundNode.addChild(background)
            
            let background1 = createBackgroundNode1()
            background1.anchorPoint = CGPointZero
            background1.position = CGPoint(x: CGFloat(i)*background1.size.width, y: 0)
            background1.name = "background1"
            platformNode.addChild(background1)
        }
        
        print("HI")
        
//        physicsWorld.gravity = CGVector(dx: 0.0, dy: -25)
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -80)
        physicsWorld.contactDelegate = self
//        physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRectMake(playableRect.origin.x, playableRect.origin.y, playableRect.size.width, 100))
        
        playerNode.texture?.filteringMode = SKTextureFilteringMode.Nearest
      
        playerNode.physicsBody = SKPhysicsBody(rectangleOfSize: playerNode.size)
        playerNode.physicsBody?.dynamic = true
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.restitution = 0.0
        playerNode.physicsBody?.friction = 0.0
        playerNode.physicsBody?.angularDamping = 0.0
        playerNode.physicsBody?.linearDamping = 0.0
        playerNode.physicsBody?.mass = 100
//        playerNode.physicsBody?.mass = 1
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Player
        playerNode.physicsBody?.collisionBitMask = CollisionCategoryBitmask.Platform
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Platform
        playerNode.position = CGPoint(x: 200, y: 900)
        playerNode.zPosition = 100
        foregroundNode.addChild(playerNode)
        
        
        // ground physics container
        let water = SKSpriteNode(imageNamed: "proto_water1")
        let bottomRect = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, water.size.height)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFromRect: bottomRect)
        bottom.physicsBody?.dynamic = false
        bottom.physicsBody?.restitution = 0.0
        foregroundNode.addChild(bottom)
        
        
        let initialPlatformNode = SKSpriteNode(imageNamed: "initial_platform")
//        initialPlatformNode.name = "NODE_PLATFORM"
//        initialPlatformNode.name = "background"
//        initialPlatformNode.anchorPoint = CGPointZero
//        initialPlatformNode.position = CGPointZero
//        let rect = CGRectMake(initialPlatformNode.size.width, initialPlatformNode.size.height, initialPlatformNode.size.width, initialPlatformNode.size.height)
        
        // position of initial platform is at origin, so just take its width and height and divide by 2.
        // also, move down by 64 pixels so we don't have half a layer of blocks
        initialPlatformNode.position = CGPointMake(initialPlatformNode.size.width/2, initialPlatformNode.size.height/2 - 64)
//        initialPlatformNode.physicsBody = SKPhysicsBody(rectangleOfSize: initialPlatformNode.size)
        
        // here we create a rect for physicsbody. it assumes x and y to be the middle position of the rectangle
        let rect = CGRectMake(initialPlatformNode.position.x, initialPlatformNode.position.y, initialPlatformNode.size.width, initialPlatformNode.size.height)
        print("rect x, y: %f %f", Int(initialPlatformNode.position.x), Int(initialPlatformNode.position.y))
        
        print("minX, minY, maxX, maxY", initialPlatformNode.frame)
        
//        print("rect minX, minY, maxX, maxY:", Int(initialPlatformNode.frame)
//        print(playableRect)
//        print(rect.minX, rect.minY)
//        print(rect.origin.x, rect.origin.y)
//        print(initialPlatformNode)
        initialPlatformNode.physicsBody = SKPhysicsBody(rectangleOfSize: rect.size)
        initialPlatformNode.physicsBody?.dynamic = false
        initialPlatformNode.physicsBody?.allowsRotation = false
        initialPlatformNode.physicsBody?.restitution = 0.0
        initialPlatformNode.physicsBody?.friction = 0.0
        initialPlatformNode.physicsBody?.angularDamping = 0.0
        initialPlatformNode.physicsBody?.linearDamping = 0.0
        initialPlatformNode.zPosition = 100
        backgroundNode.addChild(initialPlatformNode)
        
        prevPlatform = initialPlatformNode
        
//        // bottom
//        let platformA = SKSpriteNode(imageNamed: "proto_player")
////        platformA.physicsBody = SKPhysicsBody(rectangleOfSize: platformA.size)
////        platformA.physicsBody?.dynamic = false
//        platformA.name = "background"
//        platformA.zPosition = 100
//        platformA.position = CGPointMake(playableRect.origin.x, playableRect.origin.y)
////        print("playable rect", playableRect)
////        print("playable rect top", playableRect.origin.y)
////        print("playable rect bot", playableRect.height)
////        print("frame", frame)
//        foregroundNode.addChild(platformA)
//        
//        // top
//        let platformB = SKSpriteNode(imageNamed: "proto_player")
//        //        platformA.physicsBody = SKPhysicsBody(rectangleOfSize: platformA.size)
//        //        platformA.physicsBody?.dynamic = false
//        platformB.name = "background"
//        platformB.zPosition = 100
//        platformB.position = CGPointMake(playableRect.origin.x, playableRect.origin.y + playableRect.size.height)
//        foregroundNode.addChild(platformB)
        
        // middle
//        let platformC = SKSpriteNode(imageNamed: "proto_player")
//                platformA.physicsBody = SKPhysicsBody(rectangleOfSize: platformA.size)
//                platformA.physicsBody?.dynamic = false
//        platformC.name = "background"
//        platformC.zPosition = 100
//        platformC.position = CGPointMake(playableRect.origin.x+300, (playableRect.origin.y + playableRect.size.height)/2)
//        backgroundNode.addChild(platformC)
        
        
//        let actionSpawnPlatform = SKAction.runBlock(spawnPlatform)
//        let wait = SKAction.waitForDuration(2)
//        let seq = SKAction.sequence([wait, actionSpawnPlatform])
//        backgroundNode.runAction(seq)
        
//        runAction(SKAction.repeatActionForever(
//            SKAction.sequence([SKAction.runBlock(createPlatform),
//                SKAction.waitForDuration(2.0)])))
//        runAction(SKAction.repeatActionForever(
//            SKAction.sequence([SKAction.runBlock(spawnCat),
//                SKAction.waitForDuration(1.0)])))
        
        //debugDrawPlayableArea()
        
        createPlatform()
        createPlatform()
        createPlatform()
        createPlatform()
        createPlatform()
        createPlatform()
//        createPlatform()
//        createPlatform()
//        createPlatform()
    }
   
    override func update(currentTime: CFTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        if (didStartContact) {
            totalContactTime += dt
            print(totalContactTime)
            if (totalContactTime > 0.5) {
                contactedPlatform.physicsBody?.dynamic = true
                totalContactTime = 0
            }
        }
        
//        print("background position", Float(backgroundNode.position.x))
        
        // remove old objects
        backgroundNode.enumerateChildNodesWithName("NODE_PLATFORM", usingBlock: {
            (node, stop) in
            self.checkNodeRemoval(node, playerPosition: -self.backgroundNode.position.x)
//            print(self.backgroundNode.position.x)
            // when leaving screen, (not respective of the player), add another platform
        })
        
        moveBackground()
        moveBackground1()
        
        if (playerNode.position.x != CGFloat(200.0)) {
//            self.map.position = CGPointMake(backgroundNode.position.x - playerNode.position.x, 0)
//            playerNode.position = CGPointMake(CGFloat(200.0), playerNode.position.y)
//            print("GG")
//            view?.presentScene(MainMenuScene(size: CGSize(width: 2048, height: 1536)))
        }
        
      
        
        
        
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You lose!")
            backgroundMusicPlayer.stop()
            
            // 1
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            // 2
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            // 3
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
//        createBackgroundNode()
    }
    
    func checkNodeRemoval(node: SKNode, playerPosition: CGFloat) {
        if playerPosition > node.position.x + 1300.0 {
            node.removeFromParent()
            createPlatform()
            print("node removed")
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
//        for touch in (touches as! Set<UITouch>) {
//            //            let location = touch.locationInNode(self)
//            //
//            //            let sprite = SKSpriteNode(imageNamed:"Spaceship")
//            //
//            //            sprite.xScale = 0.5
//            //            sprite.yScale = 0.5
//            //            sprite.position = location
//            //
//            //            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
//            //
//            //            sprite.runAction(SKAction.repeatActionForever(action))
//            //
//            //            self.addChild(sprite)
//            print(touch.majorRadius)
//        }
        
//        let touch = touches.first as! UITouch
//        let touchLocation = touch.locationInNode(backgroundNode)
//        sceneTouched(touchLocation)
        let touch = touches.first as! UITouch
        tapBeganTime = touch.timestamp
        // NOTE: has to touch ground before jumping
        
        playerNode.texture = SKTexture(imageNamed: "ninja_squat_pixel")
        screenHeld = true
        
        
        
        
        
//        createPlatform()
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        
        
        if playerInAir == false {
//            playerInAir = true
//            screenHeld = false
            let touch = touches.first as! UITouch
            var tapHeldDuration = touch.timestamp - tapBeganTime
            if tapHeldDuration > 0.5 { tapHeldDuration = 0.5 }
            print(tapHeldDuration)
            
//            if (massChanged) {
//                massChanged = false
//                physicsWorld.gravity = CGVector(dx: 0.0, dy: -80.0)
//            }
            
            playerNode.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: tapHeldDuration * 1500000.0))
            playerNode.texture = SKTexture(imageNamed: "ninja_jump_pixel")
//            playerNode.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: tapHeldDuration * 7500))
        }
        
        // jump once in midair for ninjas
//        if (playerInAir) {
////            playerNode.physicsBody?.mass = 1000
////            massChanged = true
//            playerNode.physicsBody?.dynamic = false
//            playerNode.physicsBody?.dynamic = true
//            playerNode.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: -3500000.0))
////            print("touch", touch.locationInNode(foregroundNode))
////            print(playerNode.position)
////        
////            if (secondJump == false) {
////                secondJump = true
////                var tapHeldDuration = touch.timestamp - tapBeganTime
////                if tapHeldDuration > 0.3 { tapHeldDuration = 0.3 }
////                playerNode.physicsBody?.dynamic = false
////                playerNode.physicsBody?.dynamic = true
////                playerNode.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 600000.0))
////            }
////            
////            if (touch.locationInNode(foregroundNode).y < playerNode.position.y) {
////                                playerNode.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 400000.0))
////                                playerNode.physicsBody?.mass = 80
////            
////            
////            
////                playerNode.physicsBody?.dynamic = false
////                playerNode.physicsBody?.dynamic = true
////                playerNode.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 350000.0))
////                physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
////                backgroundMovePointsPerSec = 500
////                massChanged = true
////            
////            
////            
////            
////            
////            }
////            if (touch.locationInNode(foregroundNode).y > playerNode.position.y) {
////                // this case might always immediately move the ninja down as it's already moving down so quickly..
////                playerNode.physicsBody?.dynamic = false
////                playerNode.physicsBody?.dynamic = true
////                playerNode.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: -800000.0))
////            }
////            
////            if (touch.locationInNode(foregroundNode).y > playerNode.position.y) {
////                // this case might always immediately move the ninja down as it's already moving down so quickly..
////                
////                playerNode.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: -800000.0))
////            }
//            
//            
//        }
        
        
        
//        if (playerInAir) {
//            print("touch", touch.locationInNode(foregroundNode))
//            print(playerNode.position)
//            
//            if (touch.locationInNode(foregroundNode).y < playerNode.position.y) {
//                playerNode.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 400000.0))
//            }
//        }
        
//        playerNode.texture = SKTexture(imageNamed: "ninja_jump_pixel")
        screenHeld = false
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
//        let touch = touches.first as! UITouch
//        let touchLocation = touch.locationInNode(backgroundNode)
//        sceneTouched(touchLocation)
    }
    
    
    
    
    
    func didBeginContact(contact: SKPhysicsContact) {
        didStartContact = true
        // 1
        var updateHUD = false
        
//        if (massChanged) {
//            playerNode.physicsBody?.mass = 100
////            physicsWorld.gravity = CGVector(dx: 0.0, dy: -80)
////            backgroundMovePointsPerSec = 1400
//            massChanged = false
//        }
        
        secondJump = false
        
        // 2
//        let nonPlayerNode = (contact.bodyA.node == playerNode) ? contact.bodyB.node : contact.bodyA.node
//        let platformNode = nonPlayerNode as! GameObjectNode
        // remove the following line later..it's a bit buggy right now cuz we didn't consider water
//        playerInAir = false
        playerNode.texture = SKTexture(imageNamed: "ninja_pixel")
        if (screenHeld) {
            playerNode.texture = SKTexture(imageNamed: "ninja_squat_pixel")
        }
        
        if (contact.bodyA.node?.name == "NODE_PLATFORM") {
            playerInAir = false
            let platformNode = contact.bodyA.node as! SKSpriteNode
//            platformNode.physicsBody?.dynamic = true
            print(CGFloat(contact.contactPoint.x) - CGFloat(backgroundNode.position.x))
            print(platformNode.position)
            if (contact.contactPoint.y + 200 > platformNode.position.y) {
                platformNode.physicsBody?.dynamic = true
            }
        } else if (contact.bodyB.node?.name == "NODE_PLATFORM") {
            playerInAir = false
            let platformNode = contact.bodyB.node as! SKSpriteNode
            contactedPlatform = playerNode
            //            platformNode.physicsBody?.dynamic = true
            print(contact.contactPoint.x - backgroundNode.position.x)
            print(platformNode.convertPoint(platformNode.position, fromNode: self))
            print(contact.contactPoint)
            print(platformNode.position)
            if (contact.contactPoint.y > platformNode.position.y) {
                if (contact.contactPoint.x - backgroundNode.position.x + playerNode.position.x > platformNode.position.x-platformNode.size.width/CGFloat(2)) {
                    if (contact.contactPoint.x - backgroundNode.position.x < platformNode.position.x + platformNode.size.width/CGFloat(2)) {
////                        platformNode.physicsBody?.dynamic = true
////                        platformNode.physicsBody?.mass = 1000
////                        platformNode.physicsBody?.applyForce(CGVectorMake(0, 100000000000000))
//                        let actionMove = SKAction.moveToY(-200, duration: 1.0)
//                        platformNode.runAction(actionMove)
                        physicsWorld.gravity = CGVector(dx: 0.0, dy: -20)
                        platformNode.physicsBody?.dynamic = true
//                        massChanged = true
                    }
                }
            }
//            platformNode.physicsBody?.dynamic = true
        }
        
        // 3
//        updateHUD = other.collisionWithPlayer(playerNode)
        
        // Update the HUD if necessary
        if updateHUD {
            // 4 TODO: Update HUD in Part 2
//            print("hit platform")
        }
//        print("hit platform")
        
        // if it hit a platform..
//        playerInAir = false
        
        if (!screenHeld) {
//            playerNode.texture = SKTexture(imageNamed: "player_position1")
        }
        
        // for fake ground
        playerInAir = false

        
        // if he lands on the TOP of the platform, he gets a point ONCE for that platform (solved by
        // adding an identifier (random) to the platform, and keeping track of only the previous id
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        if (contact.bodyA.node?.name == "NODE_PLATFORM" || contact.bodyB.node?.name == "NODE_PLATFORM") {
            playerInAir = true
            physicsWorld.gravity = CGVector(dx: 0.0, dy: -80.0)
        }
        playerInAir = true
        didStartContact = false
    }
    
    
    
    // 2 - 8 blocks wide only
    func createPlatform() {
        print("creating platform after ", Float(prevPlatform.position.x))
        
        // to get current x origin, divide by 2 to get the divider of the origin block. then multiply by 128 (size of block). then add the prevMaxX and the distance
//        let currX = Double(blocks) / 2.0 * 128.0 + Double(platformDistance) + Double(prevMaxX)
//        print(currX)
        
        // change to a better random
        let rand = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        if rand < CGFloat(0.14) {
            let platform = createPlatform("platform1_pixel")
        } else if rand < CGFloat(0.28) {
            let platform = createPlatform("platform2_pixel")
        } else if rand < CGFloat(0.42) {
            let platform = createPlatform("platform3_pixel")
        } else if rand < CGFloat(0.56) {
            let platform = createPlatform("platform4_pixel")
        } else if rand < CGFloat(0.70) {
            let platform = createPlatform("platform5_pixel")
        } else if rand < CGFloat(0.84) {
            let platform = createPlatform("platform6_pixel")
        } else  {
            let platform = createPlatform("platform7_pixel")
        }
        
//        let platform = GameObjectNode()
//        let position = CGPointMake(CGFloat(currX), frame.size.height/2)
//        
//        platform.position = backgroundNode.convertPoint(position, fromNode: self)
//        let rect = CGRectMake(platform.position.x, platform.position.y, CGFloat(blocks * 128), platform.size.height)
//        platform.physicsBody = SKPhysicsBody(rectangleOfSize: rect.size)
//        platform.zPosition = 100
//        
//        platform.physicsBody?.dynamic = false
//        platform.physicsBody?.allowsRotation = false
//        platform.physicsBody?.restitution = 0.0
//        platform.physicsBody?.friction = 0.0
//        backgroundNode.addChild(platform)
//        
//        prevPlatform = platform
//        return prevPlatform
    }
    
    func createPlatform(imageName: String) -> SKSpriteNode {
//        let texture = SKTexture(imageNamed: "platform4_pixel")
//        texture.filteringMode = SKTextureFilteringMode.Nearest
//        let platform = SKSpriteNode(texture: texture)
        let platform = SKSpriteNode(imageNamed: imageName)
        platform.name = "NODE_PLATFORM"
        
        let prevMaxX = prevPlatform.frame.maxX
//        print("prev maxX", Float(prevMaxX))
        let currX = Double(platform.size.width/2.0) + Double(platformDistance) + Double(prevMaxX) + Double(backgroundNode.position.x)
        let position = CGPointMake(CGFloat(currX), randomPlatformHeight())
//        print("curr pos", position)
        
        platform.position = backgroundNode.convertPoint(position, fromNode: self)
        let rect = CGRectMake(platform.position.x, platform.position.y, platform.size.width, platform.size.height)
        platform.physicsBody = SKPhysicsBody(rectangleOfSize: rect.size)
        platform.zPosition = 100
        
        
        platform.physicsBody?.dynamic = false
        platform.physicsBody?.allowsRotation = false
        platform.physicsBody?.restitution = 0.0
        platform.physicsBody?.friction = 0.0
        backgroundNode.addChild(platform)
        prevPlatform = platform
        
        return platform
    }
    
    // playableRect.origin.x + 300 to playableRect.size.height
    func randomPlatformHeight() -> CGFloat {
//        return CGFloat(playableRect.)
        return CGFloat(arc4random_uniform(UInt32(playableRect.size.height - 300)) + 300)
    }
    
    
    func spawnPlatform() {
        // Note: positions are all in respective to their center, and starts at (0,0).
        // NOTE: rectangles and points (for both nodes and cgpoints) are different. increasing the height of
        // the rectangle moves it down; increasing the height of the node/cgpoint moves it up
        // 1. Positioning the platform node - Since the node starts at (0,0) of the total frame size (2048.0, 1536.0), we want to place the node's top on the line of the bottom playable rectangle. TO do this, subtract the half of the node's height (0, -platform.size/2) add the margin in between the frame and playable rectangle (0, -platform.size/2 + playableRect.origin.y).
        // 2. random platform heights - since we're at (0, bottom of playable rect), we can simply use the
        // playableRect's height ~ 1152. however, we need to subtract some extra offset (~300) so the platform isn't covering the entire screen
        // 3. height max (low to high) should be dependent on the previous platform's width for the user to get
        // enough height (or we could just make it so that the user can jump to the max platform height
        let offset = CGFloat(700)
        let waterHeight = CGFloat(200)
//        let maxPlatformHeight = UInt32(playableRect.origin.y + offset)
//        let minPlatformHeight = UInt32(playableRect.origin.y + playableRect.height - offset)
        print("playable rect height", playableRect.height)
        print("frame size", frame.size)
//        print("size size", self.size)
//        print("max, min: ", maxPlatformHeight, minPlatformHeight)
        let randomPlatformHeight = arc4random_uniform(UInt32(playableRect.size.height - offset)) + 200
        print("random height: ", randomPlatformHeight)
        var platform: SKSpriteNode
        if Float(arc4random())/Float(UINT32_MAX) < 0.7 {
            platform = SKSpriteNode(imageNamed: "proto_platform_1000")
        } else {
            platform = SKSpriteNode(imageNamed: "proto_platform_700")
        }
//        platform.anchorPoint = CGPointMake(0, 1)
//        let basePlatformHeight = -platform.size.height/2
        let position = CGPointMake(size.width + 500, -platform.size.height/2 + playableRect.origin.y + CGFloat(randomPlatformHeight))
//        let position = CGPointMake(size.width + 500, -platform.size.height/2 + playableRect.origin.y + CGFloat(100))
        platform.position = backgroundNode.convertPoint(position, fromNode: self)
        print(backgroundNode.position)
//        platform.name = "background"
        platform.zPosition = 100
        platform.physicsBody = SKPhysicsBody(rectangleOfSize: platform.size)
        platform.physicsBody?.dynamic = false
        platform.physicsBody?.allowsRotation = false
        platform.physicsBody?.restitution = 0.0
        platform.physicsBody?.friction = 0.0
        backgroundNode.addChild(platform)
        
        
    }
    
    
    
    
    
    func createBackgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        var backgroundWidth: CGFloat = 0
        var backgroundHeight: CGFloat = 0
        
        for i in 0...3 {
//            let texture = SKTexture(imageNamed: String(format: "proto_background%d", i+1))
//            texture.filteringMode = SKTextureFilteringMode.Nearest
//            let node = SKSpriteNode(texture: texture)
            let node = SKSpriteNode(imageNamed: String(format: "background%d", i+1))
            let xPosition = CGFloat(i) * CGFloat(node.size.width)
            node.anchorPoint = CGPointZero
            node.position = CGPoint(x: xPosition, y: CGFloat(0))
            backgroundNode.addChild(node)
            backgroundWidth += node.size.width
            if backgroundHeight == 0 { backgroundHeight = node.size.height }
        }
        backgroundNode.size = CGSize(width: backgroundWidth, height: backgroundHeight)
//        print(backgroundNode.size)
        
        return backgroundNode
    }
    
    
    func createBackgroundNode1() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        var backgroundWidth: CGFloat = 0
        var backgroundHeight: CGFloat = 0
        
        for i in 0...3 {
            //            let texture = SKTexture(imageNamed: String(format: "proto_background%d", i+1))
            //            texture.filteringMode = SKTextureFilteringMode.Nearest
            //            let node = SKSpriteNode(texture: texture)
            let node = SKSpriteNode(imageNamed: String(format: "background%d", i+1))
            let xPosition = CGFloat(i) * CGFloat(node.size.width)
            node.anchorPoint = CGPointZero
            node.position = CGPoint(x: xPosition, y: CGFloat(0))
            backgroundNode.addChild(node)
            backgroundWidth += node.size.width
            if backgroundHeight == 0 { backgroundHeight = node.size.height }
        }
        backgroundNode.size = CGSize(width: backgroundWidth, height: backgroundHeight)
        //        print(backgroundNode.size)
        
        return backgroundNode
    }
    
    
//    func createPlatform() {
//        let node = SKSpriteNode(imageNamed: "enemy")
//        node.name = "platform"
//        node.position = CGPoint(x: 3000, y: 500)
//        
//        node.physicsBody = SKPhysicsBody(rectangleOfSize: node.size)
//        node.physicsBody?.dynamic = true
//        node.physicsBody?.restitution = 0.0
//        node.physicsBody?.friction = 0.0
//        node.physicsBody?.angularDamping = 0.0
//        node.physicsBody?.linearDamping = 0.0
//        node.physicsBody?.density = 100.0
//    
//        
////        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Platform
////        node.physicsBody?.collisionBitMask = 0
//        
////        backgroundNode.addChild(node)
//    }
    
    
    
//    func backgroundNode() -> SKSpriteNode {
//        // 1
//        let backgroundNode = SKSpriteNode()
//        backgroundNode.anchorPoint = CGPointZero
//        backgroundNode.name = "background"
//        // 2
//        let background1 = SKSpriteNode(imageNamed: "background1")
//        background1.anchorPoint = CGPointZero
//        background1.position = CGPoint(x: 0, y: 0)
//        backgroundNode.addChild(background1)
//        // 3
//        let background2 = SKSpriteNode(imageNamed: "background2")
//        background2.anchorPoint = CGPointZero
//        background2.position =
//            CGPoint(x: background1.size.width, y: 0)
//        backgroundNode.addChild(background2)
//        // 4
//        backgroundNode.size = CGSize(
//            width: background1.size.width + background2.size.width,
//            height: background1.size.height)
//        return backgroundNode
//    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        let offset = location - playerNode.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
    }
    
//    func boundsCheckZombie() {
//        let bottomLeft = backgroundNode.convertPoint(
//            CGPoint(x: 0, y: CGRectGetMinY(playableRect)),
//            fromNode: self)
//        let topRight = backgroundNode.convertPoint(
//            CGPoint(x: size.width, y: CGRectGetMaxY(playableRect)),
//            fromNode: self)
//        
//        if zombie.position.x <= bottomLeft.x {
//            zombie.position.x = bottomLeft.x
//            velocity.x = -velocity.x
//        }
//        if zombie.position.x >= topRight.x {
//            zombie.position.x = topRight.x
//            velocity.x = -velocity.x
//        }
//        if zombie.position.y <= bottomLeft.y {
//            zombie.position.y = bottomLeft.y
//            velocity.y = -velocity.y
//        }
//        if zombie.position.y >= topRight.y {
//            zombie.position.y = topRight.y
//            velocity.y = -velocity.y
//        }
//    }
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(sprite.zRotation, velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: CGRectGetMinY(playableRect) + enemy.size.height/2,
                max: CGRectGetMaxY(playableRect) - enemy.size.height/2))
        backgroundNode.addChild(enemy)
        
        let actionMove =
        SKAction.moveToX(-enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
        
    }
    
    func startZombieAnimation() {
        if playerNode.actionForKey("animation") == nil {
            playerNode.runAction(
                SKAction.repeatActionForever(zombieAnimation),
                withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        playerNode.removeActionForKey("animation")
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(
            x: CGFloat.random(min: CGRectGetMinX(playableRect),
                max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(min: CGRectGetMinY(playableRect),
                max: CGRectGetMaxY(playableRect)))
        cat.setScale(0)
        backgroundNode.addChild(cat)
        
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
        
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotateByAngle(π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        let scaleUp = SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence(
            [scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeatAction(group, count: 10)
        
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.runAction(SKAction.sequence(actions))
    }
    
    func zombieHitCat(cat: SKSpriteNode) {
//        runAction(catCollisionSound)
        
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1.0)
        cat.zRotation = 0
        
        let turnGreen = SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 1.0, duration: 0.2)
        cat.runAction(turnGreen)
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
//        runAction(enemyCollisionSound)
        loseCats()
        lives--
        
        invincible = true
        
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customActionWithDuration(duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            node.hidden = remainder > slice / 2
        }
        let setHidden = SKAction.runBlock() {
            self.playerNode.hidden = false
            self.invincible = false
        }
        playerNode.runAction(SKAction.sequence([blinkAction, setHidden]))
        
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        backgroundNode.enumerateChildNodesWithName("cat") { node, _ in
            let cat = node as! SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.playerNode.frame) {
                hitCats.append(cat)
            }
        }
        for cat in hitCats {
            zombieHitCat(cat)
        }
        
        if invincible {
            return
        }
        
        var hitEnemies: [SKSpriteNode] = []
        backgroundNode.enumerateChildNodesWithName("enemy") { node, _ in
            let enemy = node as! SKSpriteNode
            if CGRectIntersectsRect(
                CGRectInset(node.frame, 20, 20), self.playerNode.frame) {
                    hitEnemies.append(enemy)
            }
        }
        for enemy in hitEnemies {
            zombieHitEnemy(enemy)
        }
    }
    
    override func didEvaluateActions()  {
        checkCollisions()
    }
    
    func moveTrain() {
        
        var targetPosition = playerNode.position
        var trainCount = 0
        
        backgroundNode.enumerateChildNodesWithName("train") { node, stop in
            trainCount++
            
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveByX(amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.runAction(moveAction)
            }
            targetPosition = node.position
            
        }
        
        if trainCount >= 30 && !gameOver {
            gameOver = true
            print("You win!")
            backgroundMusicPlayer.stop()
            // 1
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            // 2
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            // 3
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func loseCats() {
        // 1
        var loseCount = 0
        backgroundNode.enumerateChildNodesWithName("train") { node, stop in
            // 2
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            // 3
            node.name = ""
            node.runAction(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotateByAngle(π*4, duration: 1.0),
                        SKAction.moveTo(randomSpot, duration: 1.0),
                        SKAction.scaleTo(0, duration: 1.0)
                        ]),
                    SKAction.removeFromParent()
                    ]))
            // 4
            loseCount++
            if loseCount >= 2 {
                stop.memory = true
            }
        }
    }
    
    func moveBackground() {
        let backgroundVelocity = CGPoint(x: -backgroundMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        backgroundNode.position += amountToMove
        
        backgroundNode.enumerateChildNodesWithName("background") { 
            node, _ in
            let background = node as! SKSpriteNode
            let backgroundScreenPos = self.backgroundNode.convertPoint(
                background.position, toNode: self)
            if backgroundScreenPos.x <= -background.size.width {
                background.position = CGPoint(
                    x: background.position.x + background.size.width*2,
                    y: background.position.y)
            }
        }
    }
    
    func moveBackground1() {
        let backgroundVelocity = CGPoint(x: -100, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        platformNode.position += amountToMove
        
        platformNode.enumerateChildNodesWithName("background1") {
            node, _ in
            let background = node as! SKSpriteNode
            let backgroundScreenPos = self.platformNode.convertPoint(
                background.position, toNode: self)
            if backgroundScreenPos.x <= -background.size.width {
                background.position = CGPoint(
                    x: background.position.x + background.size.width*2,
                    y: background.position.y)
            }
        }
    }
    
    
}
