//
//  GameScene.swift
//  SoundDemo
//
//  Created by Phil GoGear on 22/10/15.
//  Copyright (c) 2015 Gibson Innovations. All rights reserved.
//

import SpriteKit
import AVFoundation

class BandScene: GameScene {
    var touchStarted: NSTimeInterval?
    let tapTime: NSTimeInterval = 0.2
    
    //let myAudioEngine:AVAudioEngine = AVAudioEngine()
    
    var multichannelOutputEnabled = false
    //let enviromentNode:AVAudioEnvironmentNode! = AVAudioEnvironmentNode()
    
    let bassPlayNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    var bassSoundBuffer:AVAudioPCMBuffer!
    
    let drumPlayNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    var drumSoundBuffer:AVAudioPCMBuffer!
    
    let pianoPlayNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    var pianoSoundBuffer:AVAudioPCMBuffer!
    
    let saxPlayNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    var saxSoundBuffer:AVAudioPCMBuffer!
    
    //scale of position point to meters
    //let scale:CGFloat = 0.015
    
    var bassPlaying:Bool = true
    var pianoPlaying:Bool = true
    var saxPlaying:Bool = true
    var drumPlaying:Bool = true
    
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
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
        
        let sprite = SKSpriteNode(imageNamed:"listener")
        sprite.xScale = 1.0
        sprite.yScale = 1.0
        sprite.zPosition = CGFloat(2)
        sprite.name = "listener"
        sprite.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame))
        self.addChild(sprite)
        self.listener = sprite
        
        let audioNode:SKAudioNode = SKAudioNode()
        self.addChild(audioNode)
        
        enviromentNode.reverbParameters.enable = true
        enviromentNode.reverbParameters.loadFactoryReverbPreset(.LargeRoom)
        enviromentNode.reverbParameters.level = -20
        enviromentNode.volume = 1
        enviromentNode.position = AVAudioMake3DPoint(Float(0),Float(0),Float(0))
        //let scale:CGFloat = 0.01
        let point:AVAudio3DPoint = AVAudioMake3DPoint(Float(sprite.position.x * scale),Float(0),Float(-sprite.position.y * scale))
        enviromentNode.listenerPosition = point
        
        drumSoundBuffer = loadSoundIntoBuffer("drumkit_mono",type: "wav")
        pianoSoundBuffer = loadSoundIntoBuffer("piano_mono",type: "wav")
        bassSoundBuffer = loadSoundIntoBuffer("bass_mono",type: "wav")
        saxSoundBuffer = loadSoundIntoBuffer("sax_mono",type: "wav")
        
        myAudioEngine.attachNode(enviromentNode)
        myAudioEngine.attachNode(saxPlayNode)
        myAudioEngine.attachNode(pianoPlayNode)
        myAudioEngine.attachNode(bassPlayNode)
        myAudioEngine.attachNode(drumPlayNode)
        
        updateAudioSession()
        makeEngineConnections()
        
        playAllNode()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            let touchNode = self.nodeAtPoint(location)
            if(touchNode.isKindOfClass(SKSpriteNode) && touchNode.name != "listener"){
                touchStarted = touch.timestamp
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            let touchNode = self.nodeAtPoint(location)
            if(touchNode.isKindOfClass(SKSpriteNode) && touchNode.name != "listener" && touchStarted != nil){
                let timeEnded = touch.timestamp
                if timeEnded - touchStarted! <= tapTime {
                    if(touchNode.name == "bass"){
                        let node = touchNode as! SKSpriteNode
                        touchOnNode(node, audioNode: bassPlayNode, isPlaying: bassPlaying)
                        bassPlaying = !bassPlaying
                    }else if(touchNode.name == "piano"){
                        let node = touchNode as! SKSpriteNode
                        touchOnNode(node, audioNode: pianoPlayNode, isPlaying: pianoPlaying)
                        pianoPlaying = !pianoPlaying
                    }else if(touchNode.name == "drum"){
                        let node = touchNode as! SKSpriteNode
                        touchOnNode(node, audioNode: drumPlayNode, isPlaying: drumPlaying)
                        drumPlaying = !drumPlaying
                    }else if(touchNode.name == "sax"){
                        let node = touchNode as! SKSpriteNode
                        touchOnNode(node, audioNode: saxPlayNode, isPlaying: saxPlaying)
                        saxPlaying = !saxPlaying
                    }
                }
            }
        }
        touchStarted = nil
    }
    
    
    func touchOnNode(node:SKSpriteNode,audioNode:AVAudioPlayerNode,isPlaying:Bool){
        if(isPlaying){
            node.alpha = 0.2
            audioNode.volume = 0
        }else{
            node.alpha = 1
            audioNode.volume = 1
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        touchStarted = nil
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            let touchNode = self.nodeAtPoint(location)
            
            //dont move the listener
            if(touchNode.isKindOfClass(SKSpriteNode) && touchNode.name != "listener"){
                touchNode.position = location
                if(touchNode.name == "bass"){
                    bassPlayNode.position = AVAudioMake3DPoint(Float(touchNode.position.x * scale),Float(0),Float(-touchNode.position.y * scale))
                }else if(touchNode.name == "piano"){
                    pianoPlayNode.position = AVAudioMake3DPoint(Float(touchNode.position.x * scale),Float(0),Float(-touchNode.position.y * scale))
                }else if(touchNode.name == "drum"){
                    drumPlayNode.position = AVAudioMake3DPoint(Float(touchNode.position.x * scale),Float(0),Float(-touchNode.position.y * scale))
                }else if(touchNode.name == "sax"){
                    saxPlayNode.position = AVAudioMake3DPoint(Float(touchNode.position.x * scale),Float(0),Float(-touchNode.position.y * scale))
                }
            }else if(touchNode.isKindOfClass(SKShapeNode)){
                //touchNode.position = location
                //let velocity = touch.v
            }
        }
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
        
        //audioEngine.mainMixerNode.renderingAlgorithm = algorithm
        saxPlayNode.renderingAlgorithm = algorithm
        pianoPlayNode.renderingAlgorithm = algorithm
        drumPlayNode.renderingAlgorithm = algorithm
        bassPlayNode.renderingAlgorithm = algorithm
        
        print("Set rendering algorithm: \(algorithm)")
        
        if let debugAudioNode:SKLabelNode = childNodeWithName("//debugAudioText") as? SKLabelNode{
            //debugAudioNode.text = "type:\(AVAudioSession.sharedInstance().currentRoute.outputs)"
            //usally number of avilable outputs count is 1
            let availableOuput = AVAudioSession.sharedInstance().currentRoute.outputs.count
            
            for portDesc in AVAudioSession.sharedInstance().currentRoute.outputs {
                debugAudioNode.text = ("\(availableOuput) Type:\(portDesc.portType) Channels:\(numChannels)/\(MaxNumChannels) Algorithm:\(algorithm.rawValue)")
            }
        }
    }
    
    func makeEngineConnections(){
        myAudioEngine.connect(saxPlayNode, to: enviromentNode, format: saxSoundBuffer!.format)
        myAudioEngine.connect(pianoPlayNode, to: enviromentNode, format: pianoSoundBuffer!.format)
        myAudioEngine.connect(drumPlayNode, to: enviromentNode, format: drumSoundBuffer!.format)
        myAudioEngine.connect(bassPlayNode, to: enviromentNode, format: bassSoundBuffer!.format)
        myAudioEngine.connect(enviromentNode, to: myAudioEngine.outputNode, format: constructOutputConnectionFormatForEnvironment())
        
        myAudioEngine.prepare()
        do{
            try myAudioEngine.start()
        }catch let error as NSError {
            print ("Error starting scene audio engine: \(error.domain)")
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
    
    func playAllNode(){
        saxPlayNode.scheduleBuffer(saxSoundBuffer,atTime:nil,options:.Loops,completionHandler:nil)
        pianoPlayNode.scheduleBuffer(pianoSoundBuffer,atTime:nil,options:.Loops,completionHandler:nil)
        drumPlayNode.scheduleBuffer(drumSoundBuffer,atTime:nil,options:.Loops,completionHandler:nil)
        bassPlayNode.scheduleBuffer(bassSoundBuffer,atTime:nil,options:.Loops,completionHandler:nil)
        
        saxPlayNode.play()
        pianoPlayNode.play()
        drumPlayNode.play()
        bassPlayNode.play()
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    
    func handleInterruption(notification:NSNotification){
        updateAudioSession()
        makeEngineConnections()
        playAllNode()
    }
    
    func handleSessionChange(notification:NSNotification){
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
                myAudioEngine.prepare()
                do{
                    try myAudioEngine.start()
                }catch let error as NSError {
                    print ("Error starting scene audio engine: \(error.domain)")
                }
                playAllNode()
            }
        }
    }
    
    func handleRouteChange(notification:NSNotification){
        let routeChangeTypeAsObject = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! NSNumber
        let routeChange = AVAudioSessionRouteChangeReason(rawValue:routeChangeTypeAsObject.unsignedLongValue)
        
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
}
