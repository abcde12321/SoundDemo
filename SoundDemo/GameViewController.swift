//
//  GameViewController.swift
//  SoundDemo
//
//  Created by Phil GoGear on 22/10/15.
//  Copyright (c) 2015 Gibson Innovations. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "quitScene", name: "quitScene", object: nil)
        
        let name = self.title
        loadGameScene(name!)
        
        /*if let scene = GameScene(fileNamed:name) {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
        }*/
    }
    
    func loadGameScene(gameScene:String){
        let scene:SKScene?;
        
        if(gameScene=="SurroundSoundScene"){
            scene = SurroundSoundScene(fileNamed:gameScene)!
        }else if (gameScene == "BandScene"){
            scene = BandScene(fileNamed:gameScene)!
        }else if (gameScene == "AudibleCoachScene"){
            scene = AudibleCoachScene(fileNamed:gameScene)!
        }else{
            scene = SurroundSoundScene(fileNamed:gameScene)!
        }
        
        if scene != nil {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            /* Set the scale mode to scale to fit the window */
            scene!.scaleMode = .AspectFill
            scene!.size = self.view.frame.size
            skView.presentScene(scene)
        }
    }
    
    func quitScene() {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
