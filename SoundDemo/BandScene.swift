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
    var touchStarted: TimeInterval?
    let tapTime: TimeInterval = 0.2
    
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
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        NotificationCenter.default.addObserver(self,
                                               selector: Selector(("handleInterruption:")),
                                                     name: NSNotification.Name.AVAudioEngineConfigurationChange,
            object: nil)
        //for session change
        NotificationCenter.default.addObserver(self,
                                               selector: Selector(("handleSessionChange:")),
                                                     name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance())
        
        //this does not get called
        NotificationCenter.default.addObserver(self,
                                               selector: Selector(("handleRouteChange:")),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance())
        
        let sprite = SKSpriteNode(imageNamed:"listener")
        sprite.xScale = 1.0
        sprite.yScale = 1.0
        sprite.zPosition = CGFloat(2)
        sprite.name = "listener"
        sprite.position = CGPoint(x:self.frame.midX,y:self.frame.midY)
        self.addChild(sprite)
        self.listener = sprite
        
        let audioNode:SKAudioNode = SKAudioNode()
        self.addChild(audioNode)
        
        enviromentNode.reverbParameters.enable = true
        enviromentNode.reverbParameters.loadFactoryReverbPreset(.largeRoom)
        enviromentNode.reverbParameters.level = -20
        enviromentNode.volume = 1
        enviromentNode.position = AVAudioMake3DPoint(Float(0),Float(0),Float(0))
        //let scale:CGFloat = 0.01
        let point:AVAudio3DPoint = AVAudioMake3DPoint(Float(sprite.position.x * scale),Float(0),Float(-sprite.position.y * scale))
        enviromentNode.listenerPosition = point
        
        drumSoundBuffer = loadSoundIntoBuffer(filename: "drumkit_mono",type: "wav")
        pianoSoundBuffer = loadSoundIntoBuffer(filename: "piano_mono",type: "wav")
        bassSoundBuffer = loadSoundIntoBuffer(filename: "bass_mono",type: "wav")
        saxSoundBuffer = loadSoundIntoBuffer(filename: "sax_mono",type: "wav")
        
        myAudioEngine.attach(enviromentNode)
        myAudioEngine.attach(saxPlayNode)
        myAudioEngine.attach(pianoPlayNode)
        myAudioEngine.attach(bassPlayNode)
        myAudioEngine.attach(drumPlayNode)
        
        updateAudioSession()
        makeEngineConnections()
        
        playAllNode()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchNode = self.atPoint(location)
            if(touchNode is SKSpriteNode && touchNode.name != "listener"){
                touchStarted = touch.timestamp
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchNode = self.atPoint(location)
            if(touchNode is SKSpriteNode && touchNode.name != "listener" && touchStarted != nil){
                let timeEnded = touch.timestamp
                if timeEnded - touchStarted! <= tapTime {
                    if(touchNode.name == "bass"){
                        let node = touchNode as! SKSpriteNode
                        touchOnNode(node: node, audioNode: bassPlayNode, isPlaying: bassPlaying)
                        bassPlaying = !bassPlaying
                    }else if(touchNode.name == "piano"){
                        let node = touchNode as! SKSpriteNode
                        touchOnNode(node: node, audioNode: pianoPlayNode, isPlaying: pianoPlaying)
                        pianoPlaying = !pianoPlaying
                    }else if(touchNode.name == "drum"){
                        let node = touchNode as! SKSpriteNode
                        touchOnNode(node: node, audioNode: drumPlayNode, isPlaying: drumPlaying)
                        drumPlaying = !drumPlaying
                    }else if(touchNode.name == "sax"){
                        let node = touchNode as! SKSpriteNode
                        touchOnNode(node: node, audioNode: saxPlayNode, isPlaying: saxPlaying)
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
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        touchStarted = nil
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchNode = self.atPoint(location)
            
            //dont move the listener
            if(touchNode is SKSpriteNode && touchNode.name != "listener"){
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
            }else if(touchNode is SKShapeNode){
                //touchNode.position = location
                //let velocity = touch.v
            }
        }
    }
    
    func loadSoundIntoBuffer(filename:String, type:String) -> AVAudioPCMBuffer?{
        let soundFileURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: filename, ofType: type)!)
        do{
            let soundFile = try AVAudioFile(forReading: soundFileURL as URL, commonFormat: .pcmFormatFloat32, interleaved: false)
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: soundFile.processingFormat, frameCapacity:UInt32(soundFile.length))
            try soundFile.read(into: outputBuffer!)
            return outputBuffer
        }catch let error as NSError {
            print ("Error loadSoundIntoBuffer: \(error.domain)")
        }
        return nil
    }
    
    func loadSoundIntoBuffer(filename:String) -> AVAudioPCMBuffer?{
        return loadSoundIntoBuffer(filename: filename,type: "caf")
    }
    
    func updateAudioSession(){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            let category = AVAudioSession.Category.playback
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
            if let debugImpactNode:SKLabelNode = childNode(withName: "//debugImpactText") as? SKLabelNode{
                debugImpactNode.text = "Error session: \(error.domain)"
            }
            print("Error setting avAudioSession")
        }
        
        let numChannels = AVAudioSession.sharedInstance().outputNumberOfChannels
        let MaxNumChannels = AVAudioSession.sharedInstance().maximumOutputNumberOfChannels
        
        //if there are more than 2 channels, use sound field
        let algorithm:AVAudio3DMixingRenderingAlgorithm = (numChannels <= 2) ? .HRTF : .soundField
        
        //audioEngine.mainMixerNode.renderingAlgorithm = algorithm
        saxPlayNode.renderingAlgorithm = algorithm
        pianoPlayNode.renderingAlgorithm = algorithm
        drumPlayNode.renderingAlgorithm = algorithm
        bassPlayNode.renderingAlgorithm = algorithm
        
        print("Set rendering algorithm: \(algorithm)")
        
        if let debugAudioNode:SKLabelNode = childNode(withName: "//debugAudioText") as? SKLabelNode{
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
        var numHardwareOutputChannels:AVAudioChannelCount = myAudioEngine.outputNode.outputFormat(forBus: 0).channelCount
        let hardwareSampleRate = myAudioEngine.outputNode.outputFormat(forBus: 0).sampleRate
        
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
            let environmentOutputChannelLayout:AVAudioChannelLayout = AVAudioChannelLayout(layoutTag: environmentOutputLayoutTag)!
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
        
        print("OutputFormat.channelCount:\(String(describing: environmentOutputConnectionFormat?.channelCount))/\(numHardwareOutputChannels) \(String(describing: environmentOutputConnectionFormat))")
        if let debugImpactNode:SKLabelNode = childNode(withName: "//debugImpactText") as? SKLabelNode{
            debugImpactNode.text = "\(String(describing: environmentOutputConnectionFormat))"
        }
        return environmentOutputConnectionFormat!;
    }
    
    func playAllNode(){
        saxPlayNode.scheduleBuffer(saxSoundBuffer,at:nil,options:.loops,completionHandler:nil)
        pianoPlayNode.scheduleBuffer(pianoSoundBuffer,at:nil,options:.loops,completionHandler:nil)
        drumPlayNode.scheduleBuffer(drumSoundBuffer,at:nil,options:.loops,completionHandler:nil)
        bassPlayNode.scheduleBuffer(bassSoundBuffer,at:nil,options:.loops,completionHandler:nil)
        
        saxPlayNode.play()
        pianoPlayNode.play()
        drumPlayNode.play()
        bassPlayNode.play()
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    override func continueDemo() {
        super.continueDemo()
        tryStartAudioEngine()
    }
    
    
    func handleInterruption(notification:NSNotification){
        updateAudioSession()
        makeEngineConnections()
        playAllNode()
    }
    
    func handleSessionChange(notification:NSNotification){
        let sessionChangeTypeAsObject = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
        let sessionChange = AVAudioSession.InterruptionType(rawValue: sessionChangeTypeAsObject)
        
        if let session = sessionChange{
            if session == .began{
                print("handleSessionChanged::audio session interrupt began")
                if(myAudioEngine.isRunning){
                    myAudioEngine.pause()
                }
            }else if session == .ended{
                print("handleSessionChanged::audio session interrupt ended")
                makeEngineConnections()
                tryStartAudioEngine()
                playAllNode()
            }
        }
    }
    
    func handleRouteChange(notification:NSNotification){
        let routeChangeTypeAsObject = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! NSNumber
        let routeChange = AVAudioSession.RouteChangeReason(rawValue:routeChangeTypeAsObject.uintValue)
        
        if let route = routeChange{
            if route == .unknown{
                print("handleRouteChange:Unknown ")
            }else if route == .newDeviceAvailable{
                print("handleRouteChange:NewDeviceAvailable a headset was added or removed")
            }else if route == .oldDeviceUnavailable{
                print("handleRouteChange:OldDeviceUnavailable a headset was added or removed")
            }else if route == .categoryChange{
                print("handleRouteChange:CategoryChange called at start - also when other audio wants to play")
            }else if route == .override{
                print("handleRouteChange:Override")
            }else if route == .wakeFromSleep{
                print("handleRouteChange:WakeFromSleep")
            }else if route == .noSuitableRouteForCategory{
                print("handleRouteChange:NoSuitableRouteForCategory")
            }else if route == .routeConfigurationChange{
                print("handleRouteChange:RouteConfigurationChange")
            }
        }
    }
}
