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
    //var blurView: UIVisualEffectView?
    let effectsNode = SKEffectNode()
    
    var rotationRecognizer: UIRotationGestureRecognizer!
    var rotationAngleInRadians = 0.0 as CGFloat
    
    override func didMoveToView(view: SKView){
        initSettingButtonNode()
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue("100.0f", forKey: "inputRadius")
        // Set the blur amount. Adjust this to achieve the desired effect
        let blurAmount = 10.0
        filter!.setValue(blurAmount, forKey: kCIInputRadiusKey)
        
        effectsNode.filter = filter
        effectsNode.position = self.view!.center
        effectsNode.blendMode = .Alpha
        
        // Add the effects node to the scene
        self.addChild(effectsNode)
        
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
        
        //for bluring the background
        //let bgImg = screenShot()
        
        
        /*let blurEffect: UIBlurEffect = UIBlurEffect(style: .Light)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.frame = CGRectMake(0, 0, self.frame.maxX, self.frame.maxY)
        blurView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.view!.addSubview(blurView!)*/
        
        settingMenu = NSBundle.mainBundle().loadNibNamed("SettingView", owner: self, options: nil)[0] as? UIView
        settingMenu!.frame = CGRectMake(50, 100, self.frame.maxX - 100, self.frame.maxY - 200)
        self.view?.addSubview(settingMenu!)
     
        
        /*if let settingLook:SettingView = SettingView(frame:CGRectMake(50, 100, self.frame.maxX - 100, self.frame.maxY - 200)){
            self.view?.addSubview(settingLook)
        }*/
    }
    
    func handleRotations(sender: UIRotationGestureRecognizer){
        
        /* Take the previous rotation and add the current rotation to it */
        //helloWorldLabel.transform = CGAffineTransformMakeRotation(rotationAngleInRadians + sender.rotation)
        
        /* At the end of the rotation, keep the angle for later use */
        if sender.state == .Ended{
            //rotationAngleInRadians += sender.rotation;
        }
        
    }
    
    func continueDemo(){
        //myAudioEngine.start()
        self.paused = false
        
        UIView.animateWithDuration(0.5, animations: {
            self.settingMenu?.alpha = 0.0
            },completion: {(value: Bool) in
                self.settingMenu?.removeFromSuperview()
                //self.blurView?.removeFromSuperview()
        })
        
        
    }
    
    func tryStartAudioEngine(){
        if(!myAudioEngine.running){
            myAudioEngine.prepare()
            do{
                try myAudioEngine.start()
            }catch let error as NSError {
                print ("Error starting scene audio engine: \(error.domain)")
            }
        }
    }
    
    func screenShot() -> UIImage {
        UIGraphicsBeginImageContext(UIScreen.mainScreen().bounds.size)
        //let context:CGContextRef  = UIGraphicsGetCurrentContext()!
        self.view?.drawViewHierarchyInRect(frame, afterScreenUpdates: true)
        let screenShot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return screenShot 
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