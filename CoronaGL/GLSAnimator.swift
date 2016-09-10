//
//  GLSAnimator.swift
//  InverseKinematicsTest
//
//  Created by Cooper Knaak on 10/19/14.
//  Copyright (c) 2014 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

public enum AnimationModes: CustomStringConvertible {
    
    case Linear
    case EaseIn
    case EaseOut
    case EaseInOut
    case Smoothstep
    case Sputter
    case Cycle(CGFloat)
    case Autoreverse
    case Fluctuate(FluctuatingNoise1D)
    
    public var description:String {
        switch self {
        case .Linear:
            return "Linear"
        case .EaseIn:
            return "EaseIn"
        case .EaseOut:
            return "EaseOut"
        case .EaseInOut:
            return "EaseInOut"
        case .Smoothstep:
            return "Smoothstep"
        case .Sputter:
            return "Sputter"
        case let .Cycle(speed):
            return "Cycle(\(speed))"
        case .Autoreverse:
            return "Autoreverse"
        case let .Fluctuate(fNoise):
            return "Fluctuate(\(fNoise))"
        }
    }
    
}//animation modes

public class GLSAnimationHelper: NSObject {
    
    // MARK: - Properties
    
    ///The mode controlling the timing of animation.
    public let mode:AnimationModes
    ///How long the animation is in seconds.
    public let duration:CGFloat?
    ///How many seconds have elapsed.
    public private(set) var time:CGFloat = 0.0
    
    ///Whether the animation is finished animating or not.
    public var isFinished:Bool {
        if let duration = self.duration {
            return self.time >= duration
        } else {
            return false
        }
    }
    
    ///The time when adjusted for the mode.
    public var realTime:CGFloat {
        return self.valueForTime(self.time)
    }
    
    // MARK: - Setup
    
    public init(mode:AnimationModes, duration:CGFloat?) {
        
        self.mode = mode
        self.duration = duration
        
        super.init()
    }
    
    // MARK: - Logic
    
    func valueForTime(time:CGFloat) -> CGFloat {
            
        //NOTE: Some enumeration values depend on having a valid duration,
        //so I force unwrap it.
        
        let t:CGFloat
        if let duration = self.duration {
            t = self.time / duration
        } else {
            t = self.time
        }
        
        switch(self.mode) {
            
        case .Linear:
            return t
            
        case .EaseIn:
            return 1.0 - cos(CGFloat(M_PI_2) * t)
            
        case .EaseOut:
            return sin(CGFloat(M_PI_2) * t)
            
        case .EaseInOut:
            return (1.0 - cos(CGFloat(M_PI) * t)) / 2.0
            
        case .Smoothstep:
            return t * t * (3.0 - 2.0 * t)
            
        case .Sputter:
            let h1 = -054.0 * t * t * t * t * t
            let h2 = +135.0 * t * t * t * t
            let h3 = -110.0 * t * t * t
            let h4 = +030.0 * t * t
            return h1 + h2 + h3 + h4
            
        case let .Cycle(speed):
            return (1.0 - cos(CGFloat(M_PI_2) * self.time * speed)) / 2.0
            
        case .Autoreverse:
            return (1.0 - cos(CGFloat(2.0 * M_PI) * t)) / 2.0
            
        case let .Fluctuate(fNoise):
            return fNoise.value
            
        }//get time for mode
    }
    
    public func update(dt:CGFloat) {
        
        self.time += dt
        
        if case let .Fluctuate(fNoise) = self.mode {
            fNoise.update(dt)
        }
        
    }//update
    
}

public class GLSAnimator: NSObject {
    
    // MARK: - Properties
    
    public let helper:GLSAnimationHelper
    
    public var isFinished:Bool { return self.helper.isFinished }
    // MARK: - Setup
    
    private init(mode:AnimationModes, duration:CGFloat?) {
        
        self.helper = GLSAnimationHelper(mode: mode, duration: duration)
        
        super.init()
    }
    
    // MARK: - Logic
    
    public func applyChangeWithTime(time:CGFloat) {
        print("Error!\nGLSAnimator::applyChangeWithTime invoked!")
    }//apply change in value
    
    public func applyChange() {
        self.applyChangeWithTime(self.helper.realTime)
    }
    
    public func endAnimation() {
        
        if let dur = self.helper.duration {
            let endTime = self.helper.valueForTime(dur)
            self.applyChangeWithTime(endTime)
        }
        
    }//end animation
    
    public func update(dt:CGFloat) {
        
        self.helper.update(dt)
        
        self.applyChange()
        
    }//update
    
}

public class GLSFloatAnimator: GLSAnimator {
    
    private let handler:(CGFloat) -> ()
    private let delta:AnimationDelta<CGFloat>
    
    public init(mode:AnimationModes, duration:CGFloat?, start:CGFloat, end:CGFloat, handler:(CGFloat) -> ()) {
        
        self.handler = handler
        self.delta = AnimationDelta(start: start, end: end)
        
        super.init(mode: mode, duration: duration)
    }
    
    public override func applyChangeWithTime(time: CGFloat) {
        self.handler(self.delta[time])
    }
    
}

public class GLSPointAnimator: GLSAnimator {
    
    private let handler:(CGPoint) -> ()
    private let delta:AnimationDelta<CGPoint>
    
    public init(mode:AnimationModes, duration:CGFloat?, start:CGPoint, end:CGPoint, handler:(CGPoint) -> ()) {
        
        self.handler = handler
        self.delta = AnimationDelta(start: start, end: end)
        
        super.init(mode: mode, duration: duration)
    }
    
    public override func applyChangeWithTime(time: CGFloat) {
        self.handler(self.delta[time])
    }
    
}

public class GLSVector3Animator: GLSAnimator {
    
    private let handler:(SCVector3) -> ()
    private let delta:AnimationDelta<SCVector3>
    
    public init(mode:AnimationModes, duration:CGFloat?, start:SCVector3, end:SCVector3, handler:(SCVector3) -> ()) {
        
        self.handler = handler
        self.delta = AnimationDelta(start: start, end: end)
        
        super.init(mode: mode, duration: duration)
    }
    
    public override func applyChangeWithTime(time: CGFloat) {
        self.handler(self.delta[time])
    }
    
}

public class GLSVector4Animator: GLSAnimator {
    
    private let handler:(SCVector4) -> ()
    private let delta:AnimationDelta<SCVector4>
    
    public init(mode:AnimationModes, duration:CGFloat?, start:SCVector4, end:SCVector4, handler:(SCVector4) -> ()) {
        
        self.handler = handler
        self.delta = AnimationDelta(start: start, end: end)
        
        super.init(mode: mode, duration: duration)
    }
    
    public override func applyChangeWithTime(time: CGFloat) {
        self.handler(self.delta[time])
    }
    
}
