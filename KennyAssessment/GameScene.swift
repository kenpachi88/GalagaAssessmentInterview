//
//  GameScene.swift
//  KennyAssessment
//
//  Created by Kenny Chen on 10/21/18.
//  Copyright © 2018 Kenny Chen. All rights reserved.
//

import SpriteKit
import GameplayKit
import Foundation
import Firebase
class GameScene: SKScene,SKPhysicsContactDelegate {
    
    var ref: DatabaseReference!
    var player = SKSpriteNode(imageNamed: "player")
    var gameArea = CGRect()
    var gameScore = 0
    var timer = Timer()
    var timerCount = 60
    let scoreLabel = SKLabelNode()
    let timerLabel = SKLabelNode()
    let gameModeLabel = SKLabelNode()
    var gameOverLabel = SKLabelNode()
    var enemyDropSpeed = 0.0
    var spawnRate = 0.0
    
    //prioritize hit tests by value
    struct PhysicCat {
        static let None: UInt32 = 0
        static let Player: UInt32 = 0b1
        static let Laser: UInt32 = 0b10
        static let Enemy: UInt32 = 0b100
    }
    
    
    override func didMove(to view: SKView) {
        checkGameMode()
        startTimer()
        configureChildren()
        self.physicsWorld.contactDelegate = self
        
    }
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth) / 2
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    @objc func updateTimer(){
        if timerCount != 0 {
            timerCount -= 1
            timerLabel.text = "\(timerCount)"
        } else {
            //END GAME
            self.removeAllActions()
            self.removeAllChildren()
            gameOverLabel.fontSize = 150
            gameOverLabel.text = " GAME OVER "
            gameOverLabel.fontColor = SKColor.white
            gameOverLabel.position = CGPoint(x: self.size.width/2, y: self.size.height*0.5)
            gameModeLabel.zPosition = 100
            self.addChild(gameOverLabel)
        }
    }
    func addScore() {
        gameScore += 1
        scoreLabel.text = "Score: \(gameScore)"
    }
    func shootLaser () {
        let laser = SKSpriteNode(imageNamed: "laser")
        laser.setScale(1)
        laser.zPosition = 1
        laser.position = CGPoint(x: player.position.x, y: player.position.y)
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.affectedByGravity = false
        laser.physicsBody?.categoryBitMask = PhysicCat.Laser
        laser.physicsBody?.collisionBitMask = PhysicCat.None
        laser.physicsBody?.contactTestBitMask = PhysicCat.Enemy
        self.addChild(laser)
        
        let moveLaser = SKAction.moveTo(y: self.size.height + laser.size.height, duration: 1)
        let deleteLaser = SKAction.removeFromParent()
        let laserSeq = SKAction.sequence([moveLaser,deleteLaser])
        laser.run(laserSeq)
    }
    
    func spawnEnemy() {
        let randomXstart = random(min: gameArea.minX, max: gameArea.maxX)
        let randomXend = random(min: gameArea.minX, max: gameArea.maxX)
        
        let startPoint = CGPoint(x: randomXstart, y: self.size.height * 1.2)
        let endpoint = CGPoint(x: randomXend, y: -self.size.height * 0.2)
        
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.setScale(1)
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = PhysicCat.Enemy
        enemy.physicsBody?.collisionBitMask = PhysicCat.None
        enemy.physicsBody?.contactTestBitMask = PhysicCat.Player | PhysicCat.Laser
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endpoint, duration: TimeInterval(enemyDropSpeed))
        let deleteEnemy = SKAction.removeFromParent()
        let enemySeq = SKAction.sequence([moveEnemy,deleteEnemy])
        enemy.run(enemySeq)
    }
    func startNewLvl() {
        let spawn = SKAction.run({self.spawnEnemy()})
        let spawnLag = SKAction.wait(forDuration: TimeInterval(spawnRate))
        let spawnSeq = SKAction.sequence([spawn,spawnLag])
        let spawnUnlmtd = SKAction.repeatForever(spawnSeq)
        self.run(spawnUnlmtd)
    }
    
    // MARK: Mechanics
    
    //RANDOM GENERATOR
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    func random(min:CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            player.position.x = location.x
            shootLaser()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let originTouch = touch.location(in: self)
            let prevTouch = touch.previousLocation(in: self)
            let amountDragged = originTouch.x - prevTouch.x
            player.position.x += amountDragged
            
            
            
            if player.position.x > gameArea.maxX - player.size.width/2 {
                player.position.x = gameArea.maxX - player.size.width/2
            }
            if player.position.x < gameArea.minX - player.size.width/2 {
                player.position.x = gameArea.minX - player.size.width/2
            }
        }
        
    }
    
    // MARK: Collision detection
    func didBegin(_ contact: SKPhysicsContact) {
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        } else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        if body1.categoryBitMask == PhysicCat.Player && body2.categoryBitMask == PhysicCat.Enemy {
            //if player collides w/ enemy
            if body1.node != nil {
                showExplosion(spawnPosition: body1.node!.position)
                body1.node?.removeFromParent()
            }
            if body2.node != nil {
                showExplosion(spawnPosition: body2.node!.position)
                body2.node?.removeFromParent()
            }
            removeAllChildren()
            self.removeAllActions()
            addChild(player)
            addChild(scoreLabel)
            addChild(timerLabel)
            addChild(gameModeLabel)
            self.ref.child("gameMode").setValue(0)
            startNewLvl()
        }
        if body1.categoryBitMask == PhysicCat.Laser && body2.categoryBitMask == PhysicCat.Enemy && body2.node!.position.y < self.size.height {
            if body2.node != nil {
                showExplosion(spawnPosition: body2.node!.position)
            }
            //if laser hits enemy
            addScore()
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
        }
    }
}
extension GameScene {
    func checkGameMode(){
        _ = self.ref.child("gameMode").observe(DataEventType.value, with: { (snapshot) in
            let mode = snapshot.value as? Int
            switch mode {
            case 1:
                self.scene?.backgroundColor = .red
                self.enemyDropSpeed = 1.5
                self.spawnRate = 0.5
                self.gameModeLabel.text = "Hard"
                self.removeAllActions()
                self.startNewLvl()
                
            default:
                self.scene?.backgroundColor = .lightGray
                self.removeAllActions()
                self.enemyDropSpeed = 5.0
                self.spawnRate = 2.0
                self.gameModeLabel.text = "Normal"
                self.startNewLvl()
            }
        })
    }
}
// MARK: Configure child & labels
extension GameScene {
    func configureChildren(){
        gameModeLabel.fontSize = 50
        gameModeLabel.fontColor = SKColor.white
        gameModeLabel.position = CGPoint(x: self.size.width * 0.7, y: self.size.height*0.9)
        gameModeLabel.zPosition = 100
        self.addChild(gameModeLabel)
        timerLabel.fontSize = 50
        timerLabel.fontColor = SKColor.white
        timerLabel.position = CGPoint(x: self.size.width/2, y: self.size.height*0.9)
        timerLabel.zPosition = 100
        timerLabel.text = "\(timerCount)"
        self.addChild(timerLabel)
        
        player.setScale(1)
        player.position = CGPoint(x: self.size.width/2, y: self.size.height * 0.2)
        player.zPosition = 0
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = PhysicCat.Player
        player.physicsBody?.collisionBitMask = PhysicCat.None
        player.physicsBody?.contactTestBitMask = PhysicCat.Enemy
        self.addChild(player)
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: self.size.width * 0.3, y: self.size.height*0.9)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
    }
}


extension GameScene {
    //explosion effect
    func showExplosion(spawnPosition: CGPoint) {
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.position = spawnPosition
        explosion.zPosition = 3
        explosion.setScale(0)
        self.addChild(explosion)
        
        let scaleIn = SKAction.scale(to: 1, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        
        let explosionSeq = SKAction.sequence([scaleIn,fadeOut,delete])
        explosion.run(explosionSeq)
    }
    
}
