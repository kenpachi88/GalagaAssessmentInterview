//
//  GameViewController.swift
//  KennyAssessment
//
//  Created by Kenny Chen on 10/21/18.
//  Copyright © 2018 Kenny Chen. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import Firebase
class GameViewController: UIViewController {

    var ref: DatabaseReference!
    override func viewDidLoad() {
        super.viewDidLoad()
        
 ref = Database.database().reference()
        _ = ref.child("gameMode").observe(DataEventType.value, with: { (snapshot) in
            let mode = snapshot.value as? Int
            switch mode {
            case 1:
                self.modeSwitch.isOn = true
                
            default:
                self.modeSwitch.isOn = false
            }
        })
    }
    
    @IBOutlet weak var modeSwitch: UISwitch!
    @IBAction func startGameTapped(_ sender: UIButton) {
        let scene = GameScene(size: CGSize(width: 1536, height: 2048))
        sender.isHidden = true
        toggleLabel.isHidden = true
        modeSwitch.isHidden = true
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            scene.scaleMode = .aspectFill
            scene.ref = ref
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            view.presentScene(scene)
        }
    }
    @IBAction func switchPressed(_ sender: UISwitch) {
        if sender.isOn {
            self.ref.child("gameMode").setValue(1)
        } else {
            self.ref.child("gameMode").setValue(0)
        }
    }
    
    @IBOutlet weak var toggleLabel: UILabel!
    override var shouldAutorotate: Bool {
        return true
    }
    

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
