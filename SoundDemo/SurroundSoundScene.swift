//
//  GameScene.swift
//  spaciousSoundDemo
//
//  Created by Phil GoGear on 27/07/15.
//  Copyright (c) 2015 Gibson Innovations. All rights reserved.
//

import SpriteKit
import AVFoundation

struct TouchInfo {
    var location:CGPoint
    var time:NSTimeInterval
}

class SurroundSoundScene: GameScene, SKPhysicsContactDelegate {
    var selectedNode:SKShapeNode?
    var history:[TouchInfo]?
    
    //var myAudioEngine:AVAudioEngine
    //let myAudioEngine = AVAudioEngine()
    //let enviromentNode:AVAudioEnvironmentNode! = AVAudioEnvironmentNode()
    let collisionPlayerNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    var collisionSoundBuffer:AVAudioPCMBuffer!
    //var collisionPlayerArray:NSMutableArray = []
    let launchPlayerNode:AVAudioPlayerNode = AVAudioPlayerNode()
    var launchSoundBuffer:AVAudioPCMBuffer!
    
    let firePlayNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    var fireSoundBuffer:AVAudioPCMBuffer!
    
    let waterPlayNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    var waterSoundBuffer:AVAudioPCMBuffer!
    
    
    //scale of position point to meters
    //let scale:CGFloat = 0.015
    
    var multichannelOutputEnabled = false
    
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        addDebugText()
  
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handleInterruption:",
            name: AVAudioEngineConfigurationChangeNotification,
            object: nil)
        //for session change
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handleSessionChange:",
            name: AVAudioSessionInterruptionNotification,
            object: AVAudioSession.sharedInstance())
        
        //this does not get called
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handleRouteChange:",
            name: AVAudioSessionRouteChangeNotification,
            object: AVAudioSession.sharedInstance())

        let physicsBody = SKPhysicsBody (edgeLoopFromRect: self.frame)
        self.physicsBody = physicsBody
        self.physicsBody?.friction = 0.4
        self.physicsBody?.collisionBitMask = 1
        self.physicsBody?.contactTestBitMask = 1
        self.physicsWorld.contactDelegate = self;
        //self.physicsBody?.dynamic = false

        let sprite = SKSpriteNode(imageNamed:"listener")
        sprite.xScale = 1.0
        sprite.yScale = 1.0
        sprite.zPosition = CGFloat(2)
        sprite.name = "listener"
        sprite.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame))
        self.addChild(sprite)

        self.listener = sprite
        
        enviromentNode.reverbParameters.enable = true
        enviromentNode.reverbParameters.loadFactoryReverbPreset(.LargeRoom)
        enviromentNode.reverbParameters.level = -20
        enviromentNode.volume = 1
        enviromentNode.position = AVAudioMake3DPoint(Float(0),Float(0),Float(0))
        //let scale:CGFloat = 0.01
        let point:AVAudio3DPoint = AVAudioMake3DPoint(Float(sprite.position.x * scale),Float(0),Float(-sprite.position.y * scale))
        enviromentNode.listenerPosition = point
        //defalut orientation is face forward, point up
        //enviromentNode.listenerVectorOrientation = AVAudio3DVectorOrientation(forward: AVAudio3DVector(x: 0,y: 0,z: -1), up:AVAudio3DVector(x: 0,y: 1,z: 0))
  
        fireSoundBuffer = loadSoundIntoBuffer("Crackling_Fireplace",type: "wav")
        waterSoundBuffer = loadSoundIntoBuffer("water-streamMono",type:"wav")
        collisionSoundBuffer = loadSoundIntoBuffer("bounce")
        launchSoundBuffer = loadSoundIntoBuffer("launchSound")
        collisionPlayerNode.reverbBlend = 0.2
        collisionPlayerNode.volume = 1
        launchPlayerNode.volume = 0.35
 
        myAudioEngine.attachNode(firePlayNode)
        myAudioEngine.attachNode(waterPlayNode)
        myAudioEngine.attachNode(collisionPlayerNode)
        myAudioEngine.attachNode(launchPlayerNode)
        myAudioEngine.attachNode(enviromentNode)
        
        updateAudioSession()
        makeEngineConnections()
        
        self.addChild(self.createBall(CGPointMake(300, 500)))
    }
    
    func loadSoundIntoBuffer(filename:String, type:String) -> AVAudioPCMBuffer?{
        let soundFileURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(filename, ofType: type)!)
        do{
            let soundFile = try AVAudioFile(forReading: soundFileURL, commonFormat: .PCMFormatFloat32, interleaved: false)
            
            let outputBuffer = AVAudioPCMBuffer(PCMFormat: soundFile.processingFormat, frameCapacity:UInt32(soundFile.length))
            
            try soundFile.readIntoBuffer(outputBuffer)
            return outputBuffer
        }catch let error as NSError {
            print ("Error loadSoundIntoBuffer: \(error.domain)")
        }
        
        return nil
    }
    
    func loadSoundIntoBuffer(filename:String) -> AVAudioPCMBuffer?{
        return loadSoundIntoBuffer(filename,type: "caf")
    }
    
    func makeEngineConnections(){
        myAudioEngine.connect(firePlayNode, to: enviromentNode, format: fireSoundBuffer?.format)
        myAudioEngine.connect(waterPlayNode, to: enviromentNode, format: waterSoundBuffer?.format)
        myAudioEngine.connect(collisionPlayerNode, to: enviromentNode, format: collisionSoundBuffer?.format)
        myAudioEngine.connect(launchPlayerNode, to: enviromentNode, format: launchSoundBuffer?.format)
        myAudioEngine.connect(enviromentNode, to: myAudioEngine.outputNode, format: constructOutputConnectionFormatForEnvironment())
        //audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: constructOutputConnectionFormatForEnvironment())
        
        // if we're connecting with a multichannel format, we need to pick a multichannel rendering algorithm
        //let renderingAlgo:AVAudio3DMixingRenderingAlgorithm = multichannelOutputEnabled ? .SoundField : .HRTF
        
        //collisionPlayerNode.renderingAlgorithm = renderingAlgo
        //collisionPlayerNode.reverbBlend = 0.3
        
        myAudioEngine.prepare()
        do{
            try self.myAudioEngine.start()
        }catch let error as NSError {
            print ("Error starting scene audio engine: \(error.domain)")
        }
    }
    
    
    func updateAudioSession(){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            let category = AVAudioSessionCategoryPlayback
            //let category = AVAudioSessionCategoryMultiRoute
            //let category = AVAudioSessionCategoryAmbient
            try audioSession.setCategory(category)
            try audioSession.setActive(true)
            
            // if channels is 6 it is for 5.1 rendering
            let desiredNumChannels = audioSession.maximumOutputNumberOfChannels
            
            // set preferred number of output channels
            try audioSession.setPreferredOutputNumberOfChannels(desiredNumChannels)
        
            print("Setting Audio Session maxNrofChannels:\(audioSession.maximumOutputNumberOfChannels) acturalNrOfChannels:\(audioSession.outputNumberOfChannels)")
            
            //let actualChannelCount = audioSession.outputNumberOfChannels
            // adapt to the actual number of output channels
        } catch let error as NSError{
            if let debugImpactNode:SKLabelNode = childNodeWithName("//debugImpactText") as? SKLabelNode{
                debugImpactNode.text = "Error session: \(error.domain)"
            }
            print("Error setting avAudioSession")
        }
        
        let numChannels = AVAudioSession.sharedInstance().outputNumberOfChannels
        let MaxNumChannels = AVAudioSession.sharedInstance().maximumOutputNumberOfChannels

        //if there are more than 2 channels, use sound field
        let algorithm:AVAudio3DMixingRenderingAlgorithm = (numChannels <= 2) ? .HRTF : .SoundField

        //myAudioEngine.mainMixerNode.renderingAlgorithm = algorithm
        collisionPlayerNode.renderingAlgorithm = algorithm
        launchPlayerNode.renderingAlgorithm = algorithm
        firePlayNode.renderingAlgorithm = algorithm
        waterPlayNode.renderingAlgorithm = algorithm
        
        /*if let audioNodeBall:SKAudioNode = childNodeWithName("//audioNodeBall") as? SKAudioNode{
            let ballAvAudioNode : AVAudioPlayerNode = audioNodeBall.avAudioNode as! AVAudioPlayerNode
            ballAvAudioNode.renderingAlgorithm = algorithm
        }
        if let blueNode:SKAudioNode = childNodeWithName("//audioNodeBall") as? SKAudioNode{
            let ballAvAudioNode : AVAudioPlayerNode = audioNodeBall.avAudioNode as! AVAudioPlayerNode
            ballAvAudioNode.renderingAlgorithm = algorithm
        }
        if let redNode:SKAudioNode = childNodeWithName("//audioNodeBall") as? SKAudioNode{
            let ballAvAudioNode : AVAudioPlayerNode = audioNodeBall.avAudioNode as! AVAudioPlayerNode
            ballAvAudioNode.renderingAlgorithm = algorithm
        }*/

        print("Set rendering algorithm: \(algorithm)")
        
        //print out
        if let debugAudioNode:SKLabelNode = childNodeWithName("//debugAudioText") as? SKLabelNode{
            //debugAudioNode.text = "type:\(AVAudioSession.sharedInstance().currentRoute.outputs)"
            //usally number of avilable outputs count is 1
            let availableOuput = AVAudioSession.sharedInstance().currentRoute.outputs.count
  
            for portDesc in AVAudioSession.sharedInstance().currentRoute.outputs {
                debugAudioNode.text = ("\(availableOuput) Type:\(portDesc.portType) Channels:\(numChannels)/\(MaxNumChannels) Algorithm:\(algorithm.rawValue)")
            }
        }
    }
    
    override func didChangeSize(oldSize: CGSize) {
        let physicsBody = SKPhysicsBody (edgeLoopFromRect: self.frame)
        self.physicsBody = physicsBody
    }

    func createBall(position: CGPoint) -> SKShapeNode {
        let ball = SKShapeNode(circleOfRadius: 20.0)
        let positionMark = SKShapeNode(circleOfRadius: 6.0)
        
        ball.fillColor = SKColor(red: CGFloat(arc4random() % 256) / 256.0, green: CGFloat(arc4random() % 256) / 256.0, blue: CGFloat(arc4random() % 256) / 256.0, alpha: 1.0)
        ball.position = position
        ball.name = "ball"
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 20.0)
        ball.physicsBody?.dynamic = true
        ball.physicsBody?.restitution = 0.5
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.mass = 5
        ball.physicsBody?.allowsRotation = true
        ball.physicsBody?.friction = 0.5
        ball.physicsBody?.collisionBitMask = 1
        //ball.physicsBody?.usesPreciseCollisionDetection = true
        ball.physicsBody?.contactTestBitMask = 1

        positionMark.fillColor = SKColor.blackColor()
        positionMark.position.y = -12
        //positionMark.physicsBody?.pinned = true;
        positionMark.physicsBody?.dynamic = false;
        ball.addChild(positionMark)
        
        /*let audioNodeBall = SKAudioNode(fileNamed: "bounce.caf")
        audioNodeBall.positional = true
        audioNodeBall.autoplayLooped = false
        audioNodeBall.name = "audioNodeBall"
        ball.addChild(audioNodeBall)
        
        let ballAvAudioNode : AVAudioPlayerNode = audioNodeBall.avAudioNode as! AVAudioPlayerNode
        ballAvAudioNode.reverbBlend = 0.3
        
        ballAvAudioNode.renderingAlgorithm = .HRTF*/
        
        return ball
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            let node = self.nodeAtPoint(location)
            if (node.name == "ball") {
                // Step 1
                selectedNode = node as? SKShapeNode;
                // Stop the sprite
                selectedNode?.physicsBody?.velocity = CGVectorMake(0,0)
                // Step 2: save information about the touch
                history = [TouchInfo(location:location, time:touch.timestamp)]
            }
            
            tryStartAudioEngine()
            if (node.name == "redNode"){
                /*if let audioNodeRed:SKAudioNode = childNodeWithName("//audioNodeRed") as? SKAudioNode {
                    let actionPlay = SKAction.play()
                    audioNodeRed.runAction(actionPlay)
                }*/
                firePlayNode.scheduleBuffer(fireSoundBuffer,atTime:nil,options:.Loops,completionHandler:nil)
                //firePlayNode.scheduleBuffer(fireSoundBuffer!, completionHandler: nil)
                firePlayNode.position = AVAudioMake3DPoint(Float(node.position.x * scale),Float(0),Float(-node.position.y * scale))
                firePlayNode.play()
            }else if(node.name == "blueNode"){
                /*if let audioNodeBlue:SKAudioNode = childNodeWithName("//audioNodeBlue") as? SKAudioNode {
                    let actionPlay = SKAction.play()
                    audioNodeBlue.runAction(actionPlay)
                }*/
                waterPlayNode.scheduleBuffer(waterSoundBuffer,atTime:nil,options:.Loops,completionHandler:nil)
                //waterPlayNode.scheduleBuffer(waterSoundBuffer!, completionHandler: nil)
                waterPlayNode.position = AVAudioMake3DPoint(Float(node.position.x * scale),Float(0),Float(-node.position.y * scale))
                waterPlayNode.play()
            }
                
            
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            
            let touchNode = self.nodeAtPoint(location)
            
            //for throwing balls
            if (selectedNode != nil) {
                // Step 1. update sprite's position
                selectedNode?.position = location
                // Step 2. save touch data at index 0
                history?.insert(TouchInfo(location:location, time:touch.timestamp),atIndex:0)
                return
            }
    
            //dont move the listener
            if(touchNode.isKindOfClass(SKSpriteNode) && touchNode.name != "listener"){
                touchNode.position = location
                if(touchNode.name == "redNode"){
                    firePlayNode.position = AVAudioMake3DPoint(Float(touchNode.position.x * scale),Float(0),Float(-touchNode.position.y * scale))
                }else if(touchNode.name == "blueNode"){
                    waterPlayNode.position = AVAudioMake3DPoint(Float(touchNode.position.x * scale),Float(0),Float(-touchNode.position.y * scale))
                }
            }else if(touchNode.isKindOfClass(SKShapeNode)){
                //touchNode.position = location
                //let velocity = touch.v
            }
        }
    }
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (selectedNode != nil && history!.count > 1) {
            var vx:CGFloat = 0.0
            var vy:CGFloat = 0.0
            var previousTouchInfo:TouchInfo?
            // Adjust this value as needed
            let maxIterations = 3
            let numElts:Int = min(history!.count, maxIterations)
            // Loop over touch history
            for index in 1...numElts {
                let touchInfo = history![index]
                let location = touchInfo.location
                if let previousLocation = previousTouchInfo?.location {
                    // Step 1
                    let dx = location.x - previousLocation.x
                    let dy = location.y - previousLocation.y
                    // Step 2
                    let dt = CGFloat(touchInfo.time - previousTouchInfo!.time)
                    // Step 3
                    vx += dx / dt
                    vy += dy / dt
                }
                previousTouchInfo = touchInfo
            }
            let count = CGFloat(numElts-1)
            // Step 4
            let velocity = CGVectorMake(vx/count,vy/count)
                selectedNode?.physicsBody?.velocity = velocity
            // Step 5
            selectedNode = nil
            history = nil
        }
        
        //stop playing audionode red or blue
        firePlayNode.stop()
        waterPlayNode.stop()
        /*if let audioNodeRed:SKAudioNode = childNodeWithName("//audioNodeRed") as? SKAudioNode {
            let actionPlay = SKAction.stop()
            audioNodeRed.runAction(actionPlay)
        }
        if let audioNodeBlue:SKAudioNode = childNodeWithName("//audioNodeBlue") as? SKAudioNode {
            let actionPlay = SKAction.stop()
            audioNodeBlue.runAction(actionPlay)
        }*/
        
    }
    
    func handleInterruption(notification:NSNotification){
        updateAudioSession()
        makeEngineConnections()

    }
    
    func handleSessionChange(notification:NSNotification){
        //let userInfo = notification.userInfo as! [String: AnyObject]
        //let type = userInfo[AVAudioSessionInterruptionTypeKey] as! AVAudioSessionInterruptionType
        
        let sessionChangeTypeAsObject = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
        
        let sessionChange = AVAudioSessionInterruptionType(rawValue: sessionChangeTypeAsObject)
        
        if let session = sessionChange{
            if session == .Began{
                print("handleSessionChanged::audio session interrupt began")
                if(myAudioEngine.running){
                    myAudioEngine.pause()
                }
            }else if session == .Ended{
                print("handleSessionChanged::audio session interrupt ended")
                makeEngineConnections()
                tryStartAudioEngine()
                /*myAudioEngine.prepare()
                do{
                    try myAudioEngine.start()
                }catch let error as NSError {
                    print ("Error starting scene audio engine: \(error.domain)")
                }*/
            }
        }   
        /*switch sessionChange {
        case .Began:
            print("handleSessionChanged::audio session began")
            if (!audioEngine.running) {
                audioEngine.prepare()
                do{
                    try self.audioEngine.start()
                }catch let error as NSError {
                    print ("Error starting scene audio engine: \(error.domain)")
                }
            }
        case .Ended:
            print("handleSessionChanged::audio session ended")
            if(audioEngine.running){
                audioEngine.stop()
            }
        }*/
    }
    
    func handleRouteChange(notification:NSNotification){
        let routeChangeTypeAsObject =
        notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! NSNumber
        
        let routeChange = AVAudioSessionRouteChangeReason(rawValue:
            routeChangeTypeAsObject.unsignedLongValue)
        
        if let route = routeChange{
            if route == .Unknown{
                print("handleRouteChange:Unknown ")
            }else if route == .NewDeviceAvailable{
                print("handleRouteChange:NewDeviceAvailable a headset was added or removed")
            }else if route == .OldDeviceUnavailable{
                print("handleRouteChange:OldDeviceUnavailable a headset was added or removed")
            }else if route == .CategoryChange{
                print("handleRouteChange:CategoryChange called at start - also when other audio wants to play")
            }else if route == .Override{
                print("handleRouteChange:Override")
            }else if route == .WakeFromSleep{
                print("handleRouteChange:WakeFromSleep")
            }else if route == .NoSuitableRouteForCategory{
                print("handleRouteChange:NoSuitableRouteForCategory")
            }else if route == .RouteConfigurationChange{
                print("handleRouteChange:RouteConfigurationChange")
            }
        }
    }
   
    func didBeginContact(contact: SKPhysicsContact) {
        //let ballListener:SKSpriteNode = childNodeWithName("//listener") as! SKSpriteNode
        playCollisionSound(contact.contactPoint, impulse:Float(contact.collisionImpulse))
        print("CollisionSound at \(contact.contactPoint) with impact \(contact.collisionImpulse)")
        /*if let audioNodeBall:SKAudioNode = childNodeWithName("//audioNodeBall") as? SKAudioNode{
            print("audioNodeBall: \(audioNodeBall.avAudioNode)")
            if(audioEngine.running){
                let ballAvAudioNode : AVAudioPlayerNode = audioNodeBall.avAudioNode as! AVAudioPlayerNode
                ballAvAudioNode.reverbBlend = 0.3
                let scale:CGFloat = 1000
                let point:AVAudio3DPoint = AVAudioMake3DPoint(Float(audioNodeBall.position.x * scale),Float(audioNodeBall.position.y * scale),Float(0))
                ballAvAudioNode.position = point
                
                if(ballAvAudioNode.playing){ ballAvAudioNode.stop() }
                
                let volumn = self.calculateVolumeForImpulse(Float(contact.collisionImpulse))
                let playbackRate = self.calculatePlaybackRateForImpulse(Float(contact.collisionImpulse))
                ballAvAudioNode.volume = volumn
                ballAvAudioNode.rate = playbackRate
                //ballAvAudioNode.play()
                
                /*if (ballAvAudioNode.playing){
                    audioNodeBall.runAction(SKAction.stop())
                }*/
                
                /*if(contact.collisionImpulse<=5000){
                    //let volumn:Float = Float(contact.collisionImpulse/5000)
                    let volumn = self.calculateVolumeForImpulse(Float(contact.collisionImpulse))
                    let playbackRate = self.calculatePlaybackRateForImpulse(Float(contact.collisionImpulse))
                    audioNodeBall.runAction(SKAction.changeVolumeTo(volumn,duration: 1))
                    audioNodeBall.runAction(SKAction.changePlaybackRateTo(playbackRate, duration: 0.2))
                //}else{
                //    audioNodeBall.runAction(SKAction.changeVolumeTo(1,duration: 1))
                }*/
                let actionPlaySound = SKAction.play()
                audioNodeBall.runAction(actionPlaySound)
                
                if let debugImpactNode:SKLabelNode = childNodeWithName("//debugImpactText") as? SKLabelNode{
                    debugImpactNode.text = "Impluse:\(NSInteger(contact.collisionImpulse)) Volumn:\(volumn) playbackRate:\(playbackRate)"
                }
                
                print("didBeginContact with impluse:\(contact.collisionImpulse) volumn:\(volumn) playbackRate:\(playbackRate)")
            }
        }*/
    }
    
    func calculateVolumeForImpulse(var impulse:Float) -> Float{
        // Simple mapping of impulse to volume
        let volMinDB:Float = -20
        let impulseMax:Float = 20000
        if (impulse > impulseMax){
            impulse = impulseMax
        }
        let volDB:Float = (impulse / impulseMax * -volMinDB) + volMinDB
        let calculatedVolume = powf(10, (volDB / 20))
        print("calculated volume:\(calculatedVolume)")
        
        return calculatedVolume
    }
    
    func calculatePlaybackRateForImpulse(var impulse:Float) -> Float{
        // Simple mapping of impulse to playback rate (pitch)
        // This gives the effect of the pitch dropping as the impulse reduces
        let rateMax:Float = 1.2
        let rateMin:Float = 0.95
        let rateRange =  rateMax - rateMin
        let impulseMax:Float = 20000
        let impulseMin:Float = 100
        let impulseRange = impulseMax - impulseMin
        
        if (impulse > impulseMax)  { impulse = impulseMax }
        if (impulse < impulseMin)  { impulse = impulseMin }
        return (((impulse - impulseMin) / impulseRange) * rateRange) + rateMin
    }
    
    func addDebugText(){
        
        //debug text
        let debugAudioText = SKLabelNode.init(text:"Output: Channels:")
        debugAudioText.name = "debugAudioText"
        debugAudioText.fontSize = 10
        debugAudioText.fontName = "AvenirNext"
        debugAudioText.position = CGPointMake(self.frame.width - 120, 18)
        
        let debugImpactText = SKLabelNode.init(text:"Impact")
        debugImpactText.name = "debugImpactText"
        debugImpactText.fontSize = 10
        debugImpactText.fontName = "AvenirNext"
        debugImpactText.position = CGPointMake(self.frame.width - 120, 30)
        
        self.addChild(debugAudioText)
        self.addChild(debugImpactText)
    }
    
    func playCollisionSound(impactPosition:CGPoint, impulse:Float){
        if (myAudioEngine.running) {
             collisionPlayerNode.position = AVAudioMake3DPoint(Float(impactPosition.x * scale),Float(0),Float(-impactPosition.y * scale))
            collisionPlayerNode.scheduleBuffer(collisionSoundBuffer!, atTime: nil, options: .Interrupts, completionHandler: nil)
            collisionPlayerNode.volume = calculateVolumeForImpulse(impulse)
            collisionPlayerNode.rate = self.calculatePlaybackRateForImpulse(impulse)
            collisionPlayerNode.play()
            
            if let debugImpactNode:SKLabelNode = childNodeWithName("//debugImpactText") as? SKLabelNode{
                debugImpactNode.text = "Impact:\(NSInteger(impulse)) volumn:\(collisionPlayerNode.volume) rate:\(collisionPlayerNode.rate)"
                print("Impact:\(NSInteger(impulse)) volumn:\(collisionPlayerNode.volume) rate:\(collisionPlayerNode.rate)")
            }
        }else{
            tryStartAudioEngine()
        }
    }
    
    func playLaunchSound(){
        if(myAudioEngine.running){
            launchPlayerNode.scheduleBuffer(launchSoundBuffer!, completionHandler: nil)
            launchPlayerNode.play()
        }else{
            tryStartAudioEngine()
        }
    }
    
    func constructOutputConnectionFormatForEnvironment() -> AVAudioFormat{
        var environmentOutputConnectionFormat:AVAudioFormat?;
        var numHardwareOutputChannels:AVAudioChannelCount = myAudioEngine.outputNode.outputFormatForBus(0).channelCount
        let hardwareSampleRate = myAudioEngine.outputNode.outputFormatForBus(0).sampleRate
        
        // if we're connected to multichannel hardware, create a compatible multichannel format for the environment node
        if (numHardwareOutputChannels > 2 && numHardwareOutputChannels != 3) {
            if (numHardwareOutputChannels > 8) {numHardwareOutputChannels = 8}
            
            // find an AudioChannelLayoutTag that the environment node knows how to render to
            // this is documented in AVAudioEnvironmentNode.h
            var environmentOutputLayoutTag:AudioChannelLayoutTag;
            switch (numHardwareOutputChannels) {
            case 4:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_4
            case 5:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_5_0
            case 6:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_6_0
            case 7:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_7_0
            case 8:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_8
            default:
                // based on our logic, we shouldn't hit this case
                environmentOutputLayoutTag = kAudioChannelLayoutTag_Stereo;
                break;
            }
            
            // using that layout tag, now construct a format
            let environmentOutputChannelLayout:AVAudioChannelLayout = AVAudioChannelLayout(layoutTag: environmentOutputLayoutTag)
            environmentOutputConnectionFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channelLayout: environmentOutputChannelLayout)
            print("constructOutputConnectionFormatForEnvironment::multichannelOutputEnabled")
            multichannelOutputEnabled = true
        }
        else {
            // stereo rendering format, rendering at least 2 channels cause the algorithm we are using
            environmentOutputConnectionFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channels: 2)
            multichannelOutputEnabled = false
            
            //if use stereomatrix it will have effect on multi channels only play stereo (Apple bugs?) 
            //let environmentOutputChannelLayout:AVAudioChannelLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_MatrixStereo)
            //environmentOutputConnectionFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channelLayout: environmentOutputChannelLayout)
            print("constructOutputConnectionFormatForEnvironment::multichannelOutputEnabled not")
        }
        
        print("OutputFormat.channelCount:\(environmentOutputConnectionFormat?.channelCount)/\(numHardwareOutputChannels) \(environmentOutputConnectionFormat)")
        if let debugImpactNode:SKLabelNode = childNodeWithName("//debugImpactText") as? SKLabelNode{
            debugImpactNode.text = "\(environmentOutputConnectionFormat)"
        }
        return environmentOutputConnectionFormat!;
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
