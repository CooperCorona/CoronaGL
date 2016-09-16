//
//  GLSNode+Animation.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 12/10/14.
//  Copyright (c) 2014 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaStructures

open class AnimationStructContainer {
    
    open var inAnimationBlock = false
    open var animationMode:AnimationModes = .linear
    open var animationDuration:CGFloat? = nil
    open var animationSpeed:CGFloat = 1.0
    
}

public extension GLSNode {
    
    // MARK: - Types
    
    enum Timing {
        case after
        case with
    }
    typealias AnimationDictionary = [String:Any]
    
    // MARK: - Variables
    
    public class var animationInstance:AnimationStructContainer {
        struct StaticInstance {
            static let instance = AnimationStructContainer()
        }
        return StaticInstance.instance
    }
    
    public var inAnimationBlock:Bool {
        get {
            return GLSNode.animationInstance.inAnimationBlock
        } set {
            GLSNode.animationInstance.inAnimationBlock = newValue
        }
    }
    
    public var animationMode:AnimationModes {
        get {
            return GLSNode.animationInstance.animationMode
        } set {
            GLSNode.animationInstance.animationMode = newValue
        }
    }
    
    public var animationDuration:CGFloat? {
        get {
            return GLSNode.animationInstance.animationDuration
        } set {
            GLSNode.animationInstance.animationDuration = newValue
        }
    }
    
    public var animationSpeed:CGFloat {
        get {
            return GLSNode.animationInstance.animationSpeed
        } set {
            GLSNode.animationInstance.animationSpeed = newValue
        }
    }
    
    // MARK: - Initiating Animations
    
    public class func animateWithDuration(_ duration:CGFloat?, mode:AnimationModes, block:() -> (), complete:@escaping () -> ()) {
        
        GLSNode.animationInstance.animationDuration = duration
        GLSNode.animationInstance.animationMode = mode
        GLSNode.animationInstance.animationSpeed = 1.0/*speed*/
        
        GLSNode.animationInstance.inAnimationBlock = true
        block()
        GLSNode.animationInstance.inAnimationBlock = false
        
        if let dur = duration {
            let dTime = DispatchTime.now() + Double(Int64(CGFloat(NSEC_PER_SEC) * dur)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: dTime, execute: {
                complete()
            })
        }//valid duration

    }//animate with duration
    
    public class func animateWithDuration(_ duration:CGFloat?, mode:AnimationModes, block:() -> ()) {
        self.animateWithDuration(duration, mode: mode, block: block) {
            //Do nothing...
        }
        /*
        GLSNode.animationInstance.animationDuration = duration
        GLSNode.animationInstance.animationMode = mode
        GLSNode.animationInstance.animationSpeed = speed

        GLSNode.animationInstance.inAnimationBlock = true
        block()
        GLSNode.animationInstance.inAnimationBlock = false
        */
    }//animate with duration
    
    ///Uses .EaseInOut mode and default speed of 1.0
    public class func animateWithDuration(_ duration:CGFloat, block:() -> ()) {
        GLSNode.animateWithDuration(duration, mode: .easeInOut, block: block)
    }
    
    public class func performAnimation(_ animation:AnimationDictionary) {
        guard let block = animation["Block"] as? () -> () else {
            return
        }
        
        func parseCGFloat(_ key:String) -> CGFloat? {
            switch animation[key] {
            case let dur as CGFloat:
                return dur
            case let dur as Double:
                return CGFloat(dur)
            case let dur as Float:
                return CGFloat(dur)
            case let dur as Int:
                return CGFloat(dur)
            default:
                return nil
            }
        }
        
        let duration    = parseCGFloat("Duration")
        let mode        = animation["Mode"] as? AnimationModes ?? .smoothstep
        let complete    = animation["Complete"] as? () -> ()
//        let timing      = animation["Timing"] as? Timing ?? .After
        let delay       = parseCGFloat("Delay")
        
        let finalBlock  = {
            if let complete = complete {
                GLSNode.animateWithDuration(duration, mode: mode, block: block, complete: complete)
            } else {
                GLSNode.animateWithDuration(duration, mode: mode, block: block)
            }
        }
        
        if let delay = delay {
            NSObject.dispatchAfter(delay) {
                finalBlock()
            }
        } else {
            finalBlock()
        }
    }
    
    public class func performAnimations(_ initialAnimations:[AnimationDictionary]) {
        var animations = initialAnimations
        guard var animation = animations.first else {
            return
        }
        
        animations.removeFirst()
        if let nextAnimation = animations.first {
            switch nextAnimation["Timing"] as? Timing {
            case .with?:
                GLSNode.performAnimation(animation)
                GLSNode.performAnimations(animations)
            case .after?:
                fallthrough
            default:
                let oldCompleteBlock = animation["Complete"] as? () -> ()
                animation["Complete"] = {
                    oldCompleteBlock?()
                    GLSNode.performAnimations(animations)
                }
                GLSNode.performAnimation(animation)
                break
            }
        } else {
            GLSNode.performAnimation(animation)
        }
        
    }
    
    // MARK: - Handling Animations
    
    public func updateAnimations(_ dt:CGFloat) {
        
        var indicesToRemove:[Int] = []
        
        for iii in 0..<self.animations.count {
            
            self.animations[iii].update(dt)
            
            if (self.animations[iii].isFinished) {
                self.animations[iii].endAnimation()
//                self.animations[iii].completionHandler?()
                indicesToRemove.append(iii)
            }//finished
            
        }//check if finished
        
        let count = indicesToRemove.count
        for i in 0..<count {
            let j = count - i - 1
            self.animations.remove(at: indicesToRemove[j])
        }//remove animations
        
    }//update animations
    
    public func stopAnimations() {
        /*
        for iii in 0..<animations.count {
            
            animations[iii].stop()
            
        }//stop animations
        */
        animations.removeAll(keepingCapacity: false)
        
    }//stop animations from animating
    
    // MARK: - Adding Animations
    
    public func add1Animation(_ start:CGFloat, end:CGFloat, function:@escaping (CGFloat) -> ()) {
//        animations.append(GLSAnimator(mode: animationMode, duration: animationDuration, speed:animationSpeed, startValue: start, endValue: end, floatFunction: function))
        let animation = GLSFloatAnimator(mode: self.animationMode, duration: self.animationDuration, start: start, end: end, handler: function)
        self.animations.append(animation)
    }//add animation-1
    
    public func add2Animation(_ start:CGPoint, end:CGPoint, function:@escaping (CGPoint) -> ()) {
        //        animations.append(GLSAnimator(mode: animationMode, duration: animationDuration, speed:animationSpeed, startValue: start, endValue: end, pointFunction: function))
        let animation = GLSPointAnimator(mode: self.animationMode, duration: self.animationDuration, start: start, end: end, handler: function)
        self.animations.append(animation)
    }//add animation-2
    
    public func add3Animation(_ start:SCVector3, end:SCVector3, function:@escaping (SCVector3) -> ()) {
//        animations.append(GLSAnimator(mode: animationMode, duration: animationDuration, speed:animationSpeed, startValue: start, endValue: end, vector3Function: function))
        let animation = GLSVector3Animator(mode: self.animationMode, duration: self.animationDuration, start: start, end: end, handler: function)
        self.animations.append(animation)
    }//add animation-3
    
    public func add4Animation(_ start:SCVector4, end:SCVector4, function:@escaping (SCVector4) -> ()) {
//        animations.append(GLSAnimator(mode: animationMode, duration: animationDuration, speed:animationSpeed, startValue: start, endValue: end, vector4Function: function))
        let animation = GLSVector4Animator(mode: self.animationMode, duration: self.animationDuration, start: start, end: end, handler: function)
        self.animations.append(animation)
    }//add animation-3
    
}//extend GLSNode
