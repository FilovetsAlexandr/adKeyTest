//
//  GameScene.swift
//  adKeyTest
//
//  Created by Alexandr Filovets on 30.10.24.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    private var fighter: SKSpriteNode!
    private let fighterCategory: UInt32 = 0x1 << 0
    private let bulletCategory: UInt32 = 0x1 << 1
    private let ballCategory: UInt32 = 0x1 << 2
    private let borderCategory: UInt32 = 0x1 << 3
    private let heartCategory: UInt32 = 0x1 << 4
    
    override func didMove(to view: SKView) {
        // Фон
        let background = SKSpriteNode(imageNamed: "Background")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = size
        background.zPosition = -1
        addChild(background)
        
        // Границы
        addBorders()
        
        // Физика
        physicsWorld.gravity = CGVector(dx: 0, dy: -1)
        physicsWorld.contactDelegate = self
        
        setupFighter()
        spawnBall(at: CGPoint(x: size.width / 2, y: size.height - 100), size: 80)
    }
    
    private func setupFighter() {
        fighter = SKSpriteNode(imageNamed: "fighter")
        fighter.size = CGSize(width: 50, height: 50)
        fighter.position = CGPoint(x: size.width / 2, y: 100)
        fighter.physicsBody = SKPhysicsBody(rectangleOf: fighter.size)
        fighter.physicsBody?.isDynamic = false
        fighter.physicsBody?.categoryBitMask = fighterCategory
        fighter.physicsBody?.contactTestBitMask = ballCategory | heartCategory
        addChild(fighter)
    }
    
    private func addBorders() {
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody?.categoryBitMask = borderCategory
        self.physicsBody?.contactTestBitMask = ballCategory
        self.physicsBody?.collisionBitMask = ballCategory
        self.physicsBody?.friction = 0
    }
    
    private func spawnBall(at position: CGPoint, size: CGFloat = 80, initialVelocity: CGVector = .zero) {
        let ball = SKSpriteNode(imageNamed: "ball")
        ball.size = CGSize(width: size, height: size)
        ball.position = position
        ball.physicsBody = SKPhysicsBody(circleOfRadius: size / 2)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.restitution = 0.8
        ball.physicsBody?.friction = 0.2
        ball.physicsBody?.linearDamping = 0.1
        ball.physicsBody?.angularDamping = 0.5
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.contactTestBitMask = bulletCategory | fighterCategory | borderCategory
        ball.physicsBody?.collisionBitMask = fighterCategory | bulletCategory | borderCategory
        ball.name = "ball_\(Int(size))"
        addChild(ball)
        
        ball.physicsBody?.velocity = initialVelocity
    }
    
    private func spawnHeart(at position: CGPoint) {
        let heart = SKSpriteNode(imageNamed: "heart")
        heart.size = CGSize(width: 30, height: 30)
        heart.position = position
        heart.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        heart.physicsBody?.isDynamic = true
        heart.physicsBody?.categoryBitMask = heartCategory
        heart.physicsBody?.contactTestBitMask = fighterCategory
        heart.physicsBody?.collisionBitMask = 0
        heart.name = "heart"
        addChild(heart)
    }
    
    func shootBullet() {
        let bullet = SKSpriteNode(color: .red, size: CGSize(width: 5, height: 15))
        bullet.position = CGPoint(x: fighter.position.x, y: fighter.position.y + 30)
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.contactTestBitMask = ballCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.velocity = CGVector(dx: 0, dy: 500)
        addChild(bullet)
        
        bullet.run(SKAction.sequence([SKAction.wait(forDuration: 2.0), SKAction.removeFromParent()]))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA.node
        let bodyB = contact.bodyB.node
        
        if let ball = (bodyA?.name?.contains("ball") == true ? bodyA : bodyB) as? SKSpriteNode,
           let bullet = (bodyA?.name == nil ? bodyA : bodyB) as? SKSpriteNode
        {
            handleBallHit(ball: ball, bullet: bullet)
        }
        
        if let heart = (bodyA?.name == "heart" ? bodyA : bodyB) as? SKSpriteNode,
           bodyA == fighter.physicsBody?.node || bodyB == fighter.physicsBody?.node
        {
            gameOver()
        }
        
        if (bodyA == fighter.physicsBody?.node && bodyB?.name?.contains("ball") == true) ||
            (bodyB == fighter.physicsBody?.node && bodyA?.name?.contains("ball") == true)
        {
            gameOver()
        }
    }
    
    private func handleBallHit(ball: SKSpriteNode, bullet: SKSpriteNode) {
        bullet.removeFromParent()
        
        let ballSize = ball.size.width
        ball.removeFromParent()
        
        if ballSize > 20 {
            let newSize = ballSize / 2
            let offset: CGFloat = 20
            
            let randomX1 = CGFloat.random(in: -150 ... -100)
            let randomY1 = CGFloat.random(in: 250...350)
            let randomX2 = CGFloat.random(in: 100...150)
            let randomY2 = CGFloat.random(in: 250...350)
            
            spawnBall(at: CGPoint(x: ball.position.x - offset, y: ball.position.y),
                      size: newSize,
                      initialVelocity: CGVector(dx: randomX1, dy: randomY1))
            
            spawnBall(at: CGPoint(x: ball.position.x + offset, y: ball.position.y),
                      size: newSize,
                      initialVelocity: CGVector(dx: randomX2, dy: randomY2))
        } else {
            if Int.random(in: 0...100) < 50 {
                spawnHeart(at: ball.position)
            }
        }
        checkForVictory()
    }
    
    private func checkForVictory() {
        if !children.contains(where: { $0.name?.contains("ball") == true }) {
            let alert = UIAlertController(title: "Вы победили!", message: "Поздравляем!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in self.restartGame() }))
            
            if let viewController = self.view?.window?.rootViewController {
                viewController.present(alert, animated: true, completion: nil)
            }
            
            // Останавливаем игру
            self.isPaused = true
        }
    }
    
    private func gameOver() {
        fighter.removeFromParent()
        
        //Алерт
        let alert = UIAlertController(title: "Game Over", message: "Вы проиграли!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in self.restartGame() }))
    
        if let viewController = self.view?.window?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
        self.isPaused = true
    }

    private func restartGame() {
        self.removeAllChildren()
        self.isPaused = false

        let background = SKSpriteNode(imageNamed: "Background")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = size
        background.zPosition = -1
        addChild(background)
        
        addBorders()
        setupFighter()
        spawnBall(at: CGPoint(x: size.width / 2, y: size.height - 100), size: 80) 
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let newPosition = CGPoint(x: location.x, y: fighter.position.y)
            fighter.position = newPosition
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        shootBullet()
    }
}
