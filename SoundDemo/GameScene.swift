//
//  GameScene.swift
//  SoundDemo
//
//  Created by Phil GoGear on 26/10/15.
//  Copyright © 2015 Gibson Innovations. All rights reserved.
//

import AVFoundation
import SpriteKit

class GameScene: SKScene {
    
    let myAudioEngine:AVAudioEngine = AVAudioEngine()
    let enviromentNode:AVAudioEnvironmentNode! = AVAudioEnvironmentNode()
    let scale:CGFloat = 0.015
    //var settingButtonNode:SKNode!
    var settingButton:UIButton!
    var settingMenu:UIView?
    
    override func didMoveToView(view: SKView){
        initSettingButtonNode()
        
    }
    
    func initSettingButtonNode(){
        let settingButton = UIButton(type: .Custom)
        settingButton.setImage(UIImage(named: "pause"), forState: .Normal)
        settingButton.setImage(UIImage(named: "pause"), forState: .Highlighted)
        let size:CGFloat = 35
        settingButton.frame = CGRectMake(self.frame.maxX - size, 10, size, size)
        
        settingButton.addTarget(self, action: Selector("settingButtonTouched"), forControlEvents: .TouchUpInside)
        
        self.view?.addSubview(settingButton)
    }

    @IBAction func BacktoMain(sender: AnyObject) {
        /*if let vc = self.view?.window?.rootViewController?.navigationController?.visibleViewController{
            vc.removeFromParentViewController()
        }*/
         NSNotificationCenter.defaultCenter().postNotificationName("quitScene", object: nil)
    }
    
    @IBAction func ContinueTouchup(sender: AnyObject) {
        continueDemo()
    }
    func settingButtonTouched(){
        myAudioEngine.pause()
        self.paused = true
        
        settingMenu = NSBundle.mainBundle().loadNibNamed("SettingView", owner: self, options: nil)[0] as? UIView
        settingMenu!.frame = CGRectMake(50, 100, self.frame.maxX - 100, self.frame.maxY - 200)
        self.view?.addSubview(settingMenu!)
     
        /*if let settingLook:SettingView = SettingView(frame:CGRectMake(50, 100, self.frame.maxX - 100, self.frame.maxY - 200)){
            self.view?.addSubview(settingLook)
        }*/
    }
    
    func continueDemo(){
        //myAudioEngine.start()
        self.paused = false
        
        settingMenu?.removeFromSuperview()
    }
    
    
    
    
    //use UIButton instead of SKnode for setting is a better solution
    /*func initSettingButtonNode(){
        if settingButtonNode == nil{
            settingButtonNode = SKSpriteNode(imageNamed: "pause")
            settingButtonNode.name = "settingButtonNode"
            settingButtonNode.position = CGPointMake(self.frame.maxX - 20, self.frame.maxY - 20)
            self.addChild(settingButtonNode)
        }
    }*/
    /*- (SKSpriteNode *)fireButtonNode
    {
    SKSpriteNode *fireNode = [SKSpriteNode spriteNodeWithImageNamed:@"fireButton.png"];
    fireNode.position = CGPointMake(fireButtonX,fireButtonY);
    fireNode.name = @"fireButtonNode";//how the node is identified later
    fireNode.zPosition = 1.0;
    return fireNode;
    }*/
    
    
}