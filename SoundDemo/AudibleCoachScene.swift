//
//  GameScene.swift
//  AudibleCoach
//
//  Created by Phil GoGear on 07/10/15.
//  Copyright (c) 2015 Gibson Innovations. All rights reserved.
//

import SpriteKit
import AVFoundation

class AudibleCoachScene: GameScene {
    //let myAudioEngine = AVAudioEngine()
    //let enviromentNode:AVAudioEnvironmentNode! = AVAudioEnvironmentNode()
    
    let coachPlayNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    var coachSoundBuffer:AVAudioPCMBuffer!
    
    let heartRateTimePitch = AVAudioUnitTimePitch()
    let heartRateDistortion = AVAudioUnitDistortion()
    
    let microphoneEQNode:AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 1)
    
    let heartRatePlayNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    var heartRateSoundBuffer:AVAudioPCMBuffer!
    
    //let waterPlayNode:AVAudioPlayerNode! = AVAudioPlayerNode()
    //var waterSoundBuffer:AVAudioPCMBuffer!
    
    //scale of position point to meters
    //let scale:CGFloat = 0.0002
    
    var multichannelOutputEnabled = false
    
    var heartRate = 60
    
    var isMicrophoneEnabled = false

    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        addDebugText()
    
        let backgroundNode = SKSpriteNode.init(imageNamed: "running-track.jpg")
        backgroundNode.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        backgroundNode.name = "background"
        backgroundNode.zPosition = -10
        backgroundNode.alpha = 0.1
        self.addChild(backgroundNode)
        
        
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
        
        let physicsBody = SKPhysicsBody (edgeLoopFrom: self.frame)
        self.physicsBody = physicsBody
        self.physicsBody?.friction = 0.4
        self.physicsBody?.collisionBitMask = 1
        self.physicsBody?.contactTestBitMask = 1
        //self.physicsWorld.contactDelegate = self;
        //self.physicsBody?.dynamic = false
        
        let sprite = SKSpriteNode(imageNamed:"listener")
        sprite.xScale = 1.0
        sprite.yScale = 1.0
        sprite.zPosition = CGFloat(2)
        sprite.name = "listener"
        sprite.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        self.addChild(sprite)

        enviromentNode.reverbParameters.enable = true
        enviromentNode.reverbParameters.loadFactoryReverbPreset(.smallRoom)
        enviromentNode.reverbParameters.level = 0
        enviromentNode.volume = 1
        enviromentNode.outputVolume = 1.0
        enviromentNode.position = AVAudioMake3DPoint(Float(0),Float(0),Float(0))
        //let scale:CGFloat = 0.01
        let point:AVAudio3DPoint = AVAudioMake3DPoint(Float(sprite.position.x * scale),Float(1.7),Float(-sprite.position.y * scale))
        enviromentNode.listenerPosition = point
        //defalut orientation is face forward, point up
        //enviromentNode.listenerVectorOrientation = AVAudio3DVectorOrientation(forward: AVAudio3DVector(x: 0,y: 0,z: -1), up:AVAudio3DVector(x: 0,y: 1,z: 0))
        
        coachSoundBuffer = loadSoundIntoBuffer(filename: "shia_mono",type: "wav")
        heartRateSoundBuffer = loadSoundIntoBuffer(filename: "heartbeat_mono",type:"wav")
        
        let filterParams = microphoneEQNode.bands[0] as AVAudioUnitEQFilterParameters
        
        filterParams.filterType = .highPass
        
        // 20hz to nyquist
        filterParams.frequency = 50.0
        
        //The value range of values is 0.05 to 5.0 octaves
        filterParams.bandwidth = 1.0
        
        filterParams.bypass = false
        
        // in db -96 db through 24 d
        //filterParams.gain = 15.0

        microphoneEQNode.globalGain = 24
        
        myAudioEngine.attach(microphoneEQNode)
        myAudioEngine.attach(coachPlayNode)
        myAudioEngine.attach(heartRatePlayNode)
        myAudioEngine.attach(heartRateTimePitch)
        myAudioEngine.attach(heartRateDistortion)
        myAudioEngine.attach(enviromentNode)
        
        updateAudioSession()
        makeEngineConnections()
        
        displayHeartRate() 
    }
    
    func setMicroPhoneEnabled(enable: Bool){
        let format = myAudioEngine.inputNode.inputFormat(forBus: 0)
        if(enable){
            isMicrophoneEnabled = true
            childNode(withName: "microphone")?.alpha = 1.0
            myAudioEngine.connect(myAudioEngine.inputNode, to: microphoneEQNode, format: format)
        }else{
            isMicrophoneEnabled = false
            childNode(withName: "microphone")?.alpha = 0.2
            myAudioEngine.disconnectNodeOutput(myAudioEngine.inputNode)
        }
    }
    
    func saySomething(sth:String,rate:Float){
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string:sth)
        utterance.rate = rate
        synthesizer.speak(utterance)
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
    
    func makeEngineConnections(){
        
        myAudioEngine.mainMixerNode.outputVolume = 1.0
        coachPlayNode.reverbBlend = 1.0
        coachPlayNode.volume = 1.0
        
        let format = myAudioEngine.inputNode.inputFormat(forBus: 0)
        myAudioEngine.connect(microphoneEQNode, to: myAudioEngine.mainMixerNode, format: format)
        myAudioEngine.connect(coachPlayNode, to: enviromentNode, format: coachSoundBuffer?.format)
        myAudioEngine.connect(heartRatePlayNode, to: heartRateTimePitch, format: heartRateSoundBuffer?.format)
        myAudioEngine.connect(heartRateTimePitch, to: heartRateDistortion, format: heartRateSoundBuffer?.format)
        myAudioEngine.connect(heartRateDistortion, to: myAudioEngine.mainMixerNode, format: heartRateSoundBuffer?.format)
        myAudioEngine.connect(enviromentNode, to: myAudioEngine.mainMixerNode, format: constructOutputConnectionFormatForEnvironment())
        
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
            let category = AVAudioSession.Category.playAndRecord
            //let category = AVAudioSessionCategoryMultiRoute
            //let category = AVAudioSessionCategoryAmbient
            try audioSession.setCategory(category, options:.duckOthers)
            try audioSession.setActive(true)
            
            //setting inputs !! crashing the compiler at the moment
            var builtInMicPort:AVAudioSessionPortDescription = AVAudioSessionPortDescription();
            let inputs = audioSession.availableInputs
            for port:AVAudioSessionPortDescription in inputs!{
                if(port.portType == AVAudioSession.Port.builtInMic){
                    builtInMicPort = port;
                    break
                }
            }
            
            for source:AVAudioSessionDataSourceDescription? in builtInMicPort.dataSources!{
                //if(source!.orientation == AVAudioSessionOrientationFront){
                if(source!.orientation == AVAudioSession.Orientation.back){
                    try builtInMicPort.setPreferredDataSource(source)
                    break
                }
            }
                        
            try audioSession.setPreferredInput(builtInMicPort)

            //setting output (channels)
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
        
        //myAudioEngine.mainMixerNode.renderingAlgorithm = algorithm
        coachPlayNode.renderingAlgorithm = algorithm
        
        
        print("Set rendering algorithm: \(algorithm)")
        
        //print out
        if let debugAudioNode:SKLabelNode = childNode(withName: "//debugAudioText") as? SKLabelNode{
            //debugAudioNode.text = "type:\(AVAudioSession.sharedInstance().currentRoute.outputs)"
            //usally number of avilable outputs count is 1
            let availableOuput = AVAudioSession.sharedInstance().currentRoute.outputs.count
            
            for portDesc in AVAudioSession.sharedInstance().currentRoute.outputs {
                debugAudioNode.text = ("\(availableOuput) Type:\(portDesc.portType) Channels:\(numChannels)/\(MaxNumChannels) Algorithm:\(algorithm.rawValue)")
            }
        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        let physicsBody = SKPhysicsBody (edgeLoopFrom: self.frame)
        self.physicsBody = physicsBody
    }
    
    func increaseHeartRateBy(value:NSInteger){
        let estValue = heartRate + value
        if (estValue < 50 || estValue > 220){
            return
        }
        heartRate += value
        displayHeartRate()
    }
    
    func displayHeartRate(){
        heartRateTimePitch.rate = Float(Float(heartRate)/Float(60))
        heartRateDistortion.bypass = true
        if(heartRate < 100 || heartRate>=200){
            heartRatePlayNode.volume = 1
        }else{
            heartRatePlayNode.volume = 0.5
        }
        if let heartRateLabel = childNode(withName: "heartrateLabel") as? SKLabelNode{
            heartRateLabel.text = "\(heartRate)bpm"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = self.atPoint(location)
            
            if(node.name == "plus"){
                increaseHeartRateBy(value: 10)
            }else if (node.name == "minus"){
                increaseHeartRateBy(value: -10)
            }
            
            if(node.name == "microphone"){
                setMicroPhoneEnabled(enable: !isMicrophoneEnabled)
            }
            
            tryStartAudioEngine()
            if (node.name == "coachNode"){
                //coachPlayNode.scheduleBuffer(coachSoundBuffer,atTime:nil,options:.Loops,completionHandler:nil)
                coachPlayNode.scheduleBuffer(coachSoundBuffer!, completionHandler: nil)
                coachPlayNode.position = AVAudioMake3DPoint(Float(node.position.x * scale),Float(1.7),Float(-node.position.y * scale))
                coachPlayNode.play()
                
            }else if (node.name=="heart"){
                heartRatePlayNode.scheduleBuffer(heartRateSoundBuffer!, completionHandler: nil)
                heartRatePlayNode.volume = 1.0
                heartRatePlayNode.play()
            }else if (node.name=="supportfemale"){
                saySomething(sth: "Your heart rate is \(heartRate) beats per minute", rate: 0.5)
            }
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            let touchNode = self.atPoint(location)
            
            //dont move the buttons etc...
            if(touchNode is SKSpriteNode && touchNode.name != "background" && touchNode.name != "heart" && touchNode.name != "minus" && touchNode.name != "plus" && touchNode.name != "supportfemale" && touchNode.name != "microphone"){
                touchNode.position = location
                if(touchNode.name == "coachNode"){
                    coachPlayNode.position = AVAudioMake3DPoint(Float(touchNode.position.x * scale),Float(1.7),Float(-touchNode.position.y * scale))
                }else if (touchNode.name == "listener"){
                    let point:AVAudio3DPoint = AVAudioMake3DPoint(Float(touchNode.position.x * scale),Float(1.7),Float(-touchNode.position.y * scale))
                    enviromentNode.listenerPosition = point
                }
            }
        }
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //coachPlayNode.stop()
    }
    

    
    func handleInterruption(notification:NSNotification){
        updateAudioSession()
        makeEngineConnections()
    }
    
    func handleSessionChange(notification:NSNotification){
        //let userInfo = notification.userInfo as! [String: AnyObject]
        //let type = userInfo[AVAudioSessionInterruptionTypeKey] as! AVAudioSessionInterruptionType
        
        let sessionChangeTypeAsObject = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
        
        let sessionChange = AVAudioSession.InterruptionType(rawValue: sessionChangeTypeAsObject)
        
        if let session = sessionChange{
            if session == .began{
                print("handleSessionChanged::audio session interrupt began")
                /*if(myAudioEngine.running){
                    myAudioEngine.pause()
                }*/
            }else if session == .ended{
                print("handleSessionChanged::audio session interrupt ended")
                makeEngineConnections()
                tryStartAudioEngine()
            }
        }
    }
    
    func handleRouteChange(notification:NSNotification){
        print("handle route change")
        let routeChangeTypeAsObject =
        notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! NSNumber
        
        let routeChange = AVAudioSession.RouteChangeReason(rawValue:
            routeChangeTypeAsObject.uintValue)
        
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

    func addDebugText(){
        
        //debug text
        let debugAudioText = SKLabelNode.init(text:"Output: Channels:")
        debugAudioText.name = "debugAudioText"
        debugAudioText.fontSize = 10
        debugAudioText.fontName = "AvenirNext"
        debugAudioText.position = CGPoint(x:self.frame.width - 120, y:18)
        
        let debugImpactText = SKLabelNode.init(text:"Impact")
        debugImpactText.name = "debugImpactText"
        debugImpactText.fontSize = 10
        debugImpactText.fontName = "AvenirNext"
        debugImpactText.position = CGPoint(x:self.frame.width - 120, y:30)
        
        self.addChild(debugAudioText)
        self.addChild(debugImpactText)
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
        } else {
            // stereo rendering format, rendering at least 2 channels cause the algorithm we are using
            //environmentOutputConnectionFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channels: 2)
            multichannelOutputEnabled = false
            
            //if use stereomatrix it will have effect on multi channels only play stereo (Apple bugs?)
            let environmentOutputChannelLayout:AVAudioChannelLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_StereoHeadphones)!
            environmentOutputConnectionFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channelLayout: environmentOutputChannelLayout)
            print("constructOutputConnectionFormatForEString(describing: nvironment::multichannelOutputEnabled not")
                }
        
        print("OutputFormat.channelCount:\(String(describing: environmentOutputConnectionFormat?.channelCount))/\(numHardwareOutputChannels) \(String(describing: environmentOutputConnectionFormat))")
        if let debugImpactNode:SKLabelNode = childNode(withName: "//debugImpactText") as? SKLabelNode{
            debugImpactNode.text = "\(String(describing: environmentOutputConnectionFormat))"
        }
        return environmentOutputConnectionFormat!;
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
