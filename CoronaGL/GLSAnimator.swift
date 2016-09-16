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
    
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case smoothstep
    case sputter
    case cycle(CGFloat)
    case autoreverse
    case fluctuate(FluctuatingNoise1D)
    
    public var description:String {
        switch self {
        case .linear:
            return "Linear"
        case .easeIn:
            return "EaseIn"
        case .easeOut:
            return "EaseOut"
        case .easeInOut:
            return "EaseInOut"
        case .smoothstep:
            return "Smoothstep"
        case .sputter:
            return "Sputter"
        case let .cycle(speed):
            return "Cycle(\(speed))"
        case .autoreverse:
            return "Autoreverse"
        case let .fluctuate(fNoise):
            return "Fluctuate(\(fNoise))"
        }
    }
    
}//animation modes

open class GLSAnimationHelper: NSObject {
    
    // MARK: - Properties
    
    ///The mode controlling the timing of animation.
    open let mode:AnimationModes
    ///How long the animation is in seconds.
    open let duration:CGFloat?
    ///How many seconds have elapsed.
    open fileprivate(set) var time:CGFloat = 0.0
    
    ///Whether the animation is finished animating or not.
    open var isFinished:Bool {
        if let duration = self.duration {
            return self.time >= duration
        } else {
            return false
        }
    }
    
    ///The time when adjusted for the mode.
    open var realTime:CGFloat {
        return self.valueForTime(self.time)
    }
    
    // MARK: - Setup
    
    public init(mode:AnimationModes, duration:CGFloat?) {
        
        self.mode = mode
        self.duration = duration
        
        super.init()
    }
    
    // MARK: - Logic
    
    func valueForTime(_ time:CGFloat) -> CGFloat {
            
        //NOTE: Some enumeration values depend on having a valid duration,
        //so I force unwrap it.
        
        let t:CGFloat
        if let duration = self.duration {
            t = self.time / duration
        } else {
            t = self.time
        }
        
        switch(self.mode) {
            
        case .linear:
            return t
            
        case .easeIn:
            return 1.0 - cos(CGFloat(M_PI_2) * t)
            
        case .easeOut:
            return sin(CGFloat(M_PI_2) * t)
            
        case .easeInOut:
            return (1.0 - cos(CGFloat(M_PI) * t)) / 2.0
            
        case .smoothstep:
            return t * t * (3.0 - 2.0 * t)
            
        case .sputter:
            let h1 = -054.0 * t * t * t * t * t
            let h2 = +135.0 * t * t * t * t
            let h3 = -110.0 * t * t * t
            let h4 = +030.0 * t * t
            return h1 + h2 + h3 + h4
            
        case let .cycle(speed):
            return (1.0 - cos(CGFloat(M_PI_2) * self.time * speed)) / 2.0
            
        case .autoreverse:
            return (1.0 - cos(CGFloat(2.0 * M_PI) * t)) / 2.0
            
        case let .fluctuate(fNoise):
            return fNoise.value
            
        }//get time for mode
    }
    
    open func update(_ dt:CGFloat) {
        
        self.time += dt
        
        if case let .fluctuate(fNoise) = self.mode {
            fNoise.update(dt)
        }
        
    }//update
    
}

open class GLSAnimator: NSObject {
    
    // MARK: - Properties
    
    open let helper:GLSAnimationHelper
    
    open var isFinished:Bool { return self.helper.isFinished }
    // MARK: - Setup
    
    fileprivate init(mode:AnimationModes, duration:CGFloat?) {
        
        self.helper = GLSAnimationHelper(mode: mode, duration: duration)
        
        super.init()
    }
    
    // MARK: - Logic
    
    open func applyChangeWithTime(_ time:CGFloat) {
        print("Error!\nGLSAnimator::applyChangeWithTime invoked!")
    }//apply change in value
    
    open func applyChange() {
        self.applyChangeWithTime(self.helper.realTime)
    }
    
    open func endAnimation() {
        
        if let dur = self.helper.duration {
            let endTime = self.helper.valueForTime(dur)
            self.applyChangeWithTime(endTime)
        }
        
    }//end animation
    
    open func update(_ dt:CGFloat) {
        
        self.helper.update(dt)
        
        self.applyChange()
        
    }//update
    
}

open class GLSFloatAnimator: GLSAnimator {
    
    fileprivate let handler:(CGFloat) -> ()
    fileprivate let delta:AnimationDelta<CGFloat>
    
    public init(mode:AnimationModes, duration:CGFloat?, start:CGFloat, end:CGFloat, handler:@escaping (CGFloat) -> ()) {
        
        self.handler = handler
        self.delta = AnimationDelta(start: start, end: end)
        
        super.init(mode: mode, duration: duration)
    }
    
    open override func applyChangeWithTime(_ time: CGFloat) {
        self.handler(self.delta[time])
    }
    
}

open class GLSPointAnimator: GLSAnimator {
    
    fileprivate let handler:(CGPoint) -> ()
    fileprivate let delta:AnimationDelta<CGPoint>
    
    public init(mode:AnimationModes, duration:CGFloat?, start:CGPoint, end:CGPoint, handler:@escaping (CGPoint) -> ()) {
        
        self.handler = handler
        self.delta = AnimationDelta(start: start, end: end)
        
        super.init(mode: mode, duration: duration)
    }
    
    open override func applyChangeWithTime(_ time: CGFloat) {
        self.handler(self.delta[time])
    }
    
}

open class GLSVector3Animator: GLSAnimator {
    
    fileprivate let handler:(SCVector3) -> ()
    fileprivate let delta:AnimationDelta<SCVector3>
    
    public init(mode:AnimationModes, duration:CGFloat?, start:SCVector3, end:SCVector3, handler:@escaping (SCVector3) -> ()) {
        
        self.handler = handler
        self.delta = AnimationDelta(start: start, end: end)
        
        super.init(mode: mode, duration: duration)
    }
    
    open override func applyChangeWithTime(_ time: CGFloat) {
        self.handler(self.delta[time])
    }
    
}

open class GLSVector4Animator: GLSAnimator {
    
    fileprivate let handler:(SCVector4) -> ()
    fileprivate let delta:AnimationDelta<SCVector4>
    
    public init(mode:AnimationModes, duration:CGFloat?, start:SCVector4, end:SCVector4, handler:@escaping (SCVector4) -> ()) {
        
        self.handler = handler
        self.delta = AnimationDelta(start: start, end: end)
        
        super.init(mode: mode, duration: duration)
    }
    
    open override func applyChangeWithTime(_ time: CGFloat) {
        self.handler(self.delta[time])
    }
    
}
