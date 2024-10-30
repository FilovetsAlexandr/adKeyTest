//
//  GameView.swift
//  adKeyTest
//
//  Created by Alexandr Filovets on 30.10.24.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .resizeFill
        return scene
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    GameView()
}
