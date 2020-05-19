//
//  GameScene.swift
//  HurricaneShip
//
//  Created by Alessandro Raiola on 15/05/2020.
//  Copyright © 2020 alessandroraiola. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var ship: SKSpriteNode!
    var meteor: SKSpriteNode!
    
    var lives: Int = 3
    
    var lastTouchLocation: CGPoint!
    var dt: TimeInterval = 0
    var velocity: CGPoint = CGPoint.zero
    var lastUpdateTime: TimeInterval = 0
    var moveShipPerSecond: CGFloat = 480
    let rotateRadiansPerSecond: CGFloat = 2.0 * π
    var gameRect: CGRect!
    
    let rotateRec = UIRotationGestureRecognizer()
    
    var theRotation:CGFloat = 0
    var offset:CGFloat = 0
    let tapRec = UITapGestureRecognizer()
    
//MARK: - Scene Management
    override func didMove(to view: SKView) {
        setupWorld()
        setupNodes()
        //setupGesture()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
    
        updateManager()
    }
//MARK: - Methods
    func setupWorld() {
        physicsWorld.contactDelegate = self
        gameRect = scene!.frame
        let rectShape = SKShapeNode(rect: gameRect)
        rectShape.strokeColor = .yellow
        
        run(SKAction.repeatForever(
          SKAction.sequence([
                SKAction.run() { [weak self] in
                    self?.randomSpawn()
                },
                SKAction.wait(forDuration: 3.0)])
            )
        )
        afterDelay(2.0) {
            self.run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.run(self.meteorSpawn),
                    SKAction.wait(forDuration: 1.5)
                ])
            ))
        }
       
    }
    
    func setupNodes() {
        ship = childNode(withName: "ship") as? SKSpriteNode
        ship.setScale(0.8)
        ship.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "ship"), size: ship.size)
        ship.physicsBody?.affectedByGravity = false
        ship.physicsBody?.allowsRotation = false
        ship.physicsBody?.categoryBitMask = PhysicsCategory.Ship
        ship.physicsBody?.collisionBitMask = PhysicsCategory.Meteor
        ship.physicsBody?.contactTestBitMask = PhysicsCategory.Meteor
    }
    
    func setupGesture() {
        /*
         * NOT CALLED
         */
        rotateRec.addTarget(self, action: #selector(GameScene.rotatedView(_:) ))
        self.view!.addGestureRecognizer(rotateRec)
        
        self.view!.isMultipleTouchEnabled = true
        self.view!.isUserInteractionEnabled = true
        
        tapRec.addTarget(self, action: #selector(GameScene.tappedView))
        tapRec.numberOfTouchesRequired = 1
        tapRec.numberOfTapsRequired = 1
        self.view!.addGestureRecognizer(tapRec)
    }
    
    func move(_ sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = CGPoint(
            x: velocity.x * CGFloat(dt),
            y: velocity.y * CGFloat(dt)
        )
        
        sprite.position = CGPoint(
            x: sprite.position.x + amountToMove.x,
            y: sprite.position.y + amountToMove.y
        )
    }
    
    func moveTorward(location: CGPoint) {
        let offset = CGPoint(
            x: location.x - ship.position.x,
            y: location.y - ship.position.y
        )
        let lenght = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        
        let direction = CGPoint(
            x: offset.x / CGFloat(lenght),
            y: offset.y / CGFloat(lenght)
        )
        
        velocity = CGPoint(
            x: direction.x * moveShipPerSecond,
            y: direction.y * moveShipPerSecond
        )
    }
    
    func rotate(_ sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSeconds: CGFloat) {
        
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSeconds * CGFloat(dt), abs(shortest))
        
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func blinkAnimation() -> SKAction {
        let duration = 0.6
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: duration)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: duration)
        let blink = SKAction.sequence([fadeOut, fadeIn])
        return SKAction.repeatForever(blink)
    }
    
    func updateManager() {
//        if let touchLocation = lastTouchLocation {
//            let diff = touchLocation - ship.position
//            if diff.length() <= (velocity * CGFloat(dt)).length() {
//                   ship.position = touchLocation
//                   velocity = CGPoint.zero
//            } else {
                move(ship, velocity: velocity)
                rotate(ship, direction: velocity, rotateRadiansPerSeconds: rotateRadiansPerSecond)
//            }
//        }
    }
//MARK: - Gesture functions
    @objc func rotatedView(_ sender:UIRotationGestureRecognizer) {
        /*
         * NOT USED
         */
        if (sender.state == .began) {
            //print("we began")
        }
        if (sender.state == .changed) {
            //print("we rotated")
            theRotation = CGFloat(sender.rotation) + self.offset
            theRotation = theRotation * -1
            ship.zRotation = theRotation
        }
        if (sender.state == .ended) {
            //print("we ended")
            self.offset = ship.zRotation * -1
        }
    }
    
    @objc func tappedView(){
        /*
         * NOT USED
         */
        //print("we tapped")
        let xVec: CGFloat = sin(theRotation) * -10
        let yVec: CGFloat = cos(theRotation) * 10
        let theVector:CGVector = CGVector(dx: xVec, dy: yVec)
        ship.physicsBody?.applyImpulse(theVector)
    }
}
//MARK: - Handling touches
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastTouchLocation = touch.location(in: self)
        moveTorward(location: lastTouchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}
//MARK: - Physics Contact Delegate
extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Ship ? contact.bodyB : contact.bodyA
        
        switch other.categoryBitMask {
        case PhysicsCategory.Meteor:
            if let meteor = other.node {
                print("### Collide with meteor!")
                meteor.removeFromParent()
                shipContact()
            }
        case PhysicsCategory.Decreaser:
            if let decrease = other.node {
                print("### Decrease size!")
                decrease.removeFromParent()
                ship.setScale(0.3)
                afterDelay(3.0) {
                    self.ship.setScale(0.8)
                }
            }
        case PhysicsCategory.Guard:
            if let guardian = other.node {
                print("### Guard found")
                guardian.removeFromParent()
                addGuard()
            }
        default:
            break
        }
        
        let guardTouch = contact.bodyA.categoryBitMask == PhysicsCategory.Guard ? contact.bodyB : contact.bodyA
        
        switch guardTouch.categoryBitMask {
        case PhysicsCategory.Meteor:
            if let meteor = guardTouch.node {
                meteor.removeFromParent()
            }
        default:
            break
        }
    }
    
    func shipContact() {
        ship.run(blinkAnimation(), withKey: AnimationKeys.Blink)
        afterDelay(3.0) {
            stopAnimationFor(self.ship, forKey: AnimationKeys.Blink)
        }
        lives -= 1
        print("lives: \(lives)")
        if lives == 0 {
            ship.removeFromParent()
            print("### GAME OVER!")
        }
    }
    
    func addGuard() {
        let guardian = SKSpriteNode(texture: SKTexture(imageNamed: "guard_01"))
        guardian.name = "guard"
        guardian.setScale(1.2)
        ship.addChild(guardian)
        
        let guardAnimation = setUpAnimationWithPrefix("guard_0", start: 1, end: 5, timePerFrame: 0.2)
        guardian.run(SKAction.repeatForever(guardAnimation))
        
        checkCollision()
    }
    
    func checkCollision() {
        enumerateChildNodes(withName: "guard") { node, _ in
            let guardian = node as! SKSpriteNode
            if guardian.frame.intersects(self.meteor.frame) {
                print("### Intersect guard")
                self.meteor.removeFromParent()
            }
        }
    }
}
//MARK: - SpawnFunction
extension GameScene {
    func randomSpawn() {
        /* random spawn */
        let _ = 100
        let bonusSpawn = 55
        
        if Int.random(min: 1, max: 100) <= bonusSpawn  {
            switchAmongPowerUp()
        } else {
            switchAmongMalus()
        }
    }

    func switchAmongPowerUp() {
        /*
         * This function switch among
         * all the powerUp to make them Spawn
         */
        let gem = SKSpriteNode(imageNamed: "invincibilità")
        let magnet = SKSpriteNode(imageNamed: "magnete")
        let slug = SKSpriteNode(imageNamed: "speedDown")
    
        let max = 100
        let slugPercentage = 90
           
        if Int.random(min: 1, max: max) <= 55 {
            SpawnFor(node: slug, charge: -1, categoryBitMask: PhysicsCategory.Decreaser, name: "bonus") //DECREASE SIZE
        } else  if Int.random(min: 1, max: max) <= slugPercentage {
            SpawnFor(node: magnet, charge: -1, categoryBitMask: PhysicsCategory.Guard, name: "magnet") //CREATE A SHIELD
        } else if Int.random(min: 1, max: max) == max  {
            SpawnFor(node: gem, charge: -1, categoryBitMask: PhysicsCategory.GoldPowerUp, name: "bonus") //TO DEFINE
        }
    }
    
    func switchAmongMalus() {
        /*
         * This function switch among
         * all the malus to make them Spawn
         */
        let malusBat = SKSpriteNode(imageNamed: "muro") //TO DEFINE PURPOSE
        let lightning = SKSpriteNode(imageNamed: "speedUp") //INCREASE SIZE
        let _ = 100
        let simpleFoodPercentage = 60
        
        if Int.random(min: 1, max: 100) <= simpleFoodPercentage {
            SpawnFor(node: malusBat,charge: -1, categoryBitMask: PhysicsCategory.None, name: "malus")
        } else /*if Int.random(min: 1, max: 100) <= slugPercentage*/ {
            SpawnFor(node: lightning, charge: -1, categoryBitMask: PhysicsCategory.Increaser, name: "malus")
        }
    }
    
    func SpawnFor(node: SKSpriteNode, charge: CGFloat, categoryBitMask: UInt32, name: String) {
        /* Function to generate a element to spawn */
        let leftPlayableWidth = gameRect.minX + node.frame.width
        let rightPlayableWidth = gameRect.maxX - node.frame.width
        let upperPlayableHeight = gameRect.minY + node.frame.height
        let lowerPlayableHeight = gameRect.maxY - node.frame.height
        node.position = CGPoint(
            x: CGFloat.random(
                min: leftPlayableWidth,
                max: rightPlayableWidth
            ),
            y: CGFloat.random(
                min: upperPlayableHeight,
                max: lowerPlayableHeight
            )
        )
        node.name = name
        node.zPosition = 2
        node.setScale(0.2)
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.charge = charge
        node.physicsBody?.categoryBitMask = categoryBitMask
        node.physicsBody?.collisionBitMask = PhysicsCategory.Ship
        node.physicsBody?.contactTestBitMask = PhysicsCategory.Ship
        addChild(node)
        
        afterDelay(2.0) {
            node.removeFromParent()
        }
    }
    
    func meteorSpawn() {
        let randomizedSpawnPosition = switchSpawnPoint()
        let journeyPoint = CGPoint(
            x: -randomizedSpawnPosition.x,
            y: -randomizedSpawnPosition.y
        )
        
        meteor = SKSpriteNode(texture: SKTexture(imageNamed: "reducto"))
        meteor.position = randomizedSpawnPosition
        meteor.setScale(0.2)
        meteor.physicsBody = SKPhysicsBody(circleOfRadius: meteor.size.width/2)
        meteor.physicsBody?.categoryBitMask = PhysicsCategory.Meteor
        meteor.physicsBody?.collisionBitMask = PhysicsCategory.Ship
        meteor.physicsBody?.contactTestBitMask = PhysicsCategory.Ship
        addChild(meteor)
        
        let moveMeteor = SKAction.move(to: journeyPoint, duration: randomizedMeteorSpeed())
        let removeMeteor = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveMeteor, removeMeteor])
        meteor.run(sequence)
    }
    
    func switchSpawnPoint() -> CGPoint {
        var point: CGPoint
        
        let rightSide: CGFloat = size.width/2
        let leftSide: CGFloat = -rightSide
        let highSide: CGFloat = size.height/2
        let lowSide: CGFloat = -highSide
        
        let lowestPoint = CGPoint(
            x: .random(min: leftSide, max: rightSide),
            y: lowSide
        )
        let highestPoint = CGPoint(
            x: .random(min: leftSide, max: rightSide),
            y: highSide
        )
        let leftPoint = CGPoint(
            x: leftSide,
            y: .random(min: lowSide, max: highSide)
        )
        let rightPoint = CGPoint(
            x: rightSide,
            y: .random(min: lowSide, max: highSide)
        )
        
        if Int.random(min: 1, max: 4) == 1 {
            point = lowestPoint
        } else if Int.random(min: 1, max: 4) == 2 {
            point = highestPoint
        } else if Int.random(min: 1, max: 4) == 3 {
            point = leftPoint
        } else {
            point = rightPoint
        }
        return point
    }
    
    func randomizedMeteorSpeed() -> TimeInterval {
        if Int.random(min: 1, max: 100) <= 30 {
            return 3
        } else if Int.random(min: 1, max: 100) <= 20 {
            return 2
        } else if Int.random(min: 1, max: 100) <= 40 {
           return 4
        } else {
           return 1
        }
    }
}
