//
//  GLSAnimatable.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 8/31/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaStructures
#if os(iOS)
    import UIKit
#endif
/**
 *  Defines a protocol for objects that can be animated.
 *  There's no way to simply annotate properties and
 *  make them animate, they have to manually override
 *  didSet property observers and call the exposed methods
 *  here.
 *
 *  **Note**: Ideally, GLSAnimatable would also work on
 *  structs, but then the methods would have to be marked
 *  mutable, and there seems to be a bug where classes
 *  cannot call mutable methods (because for some reason
 *  the compiler thinks they're immutable?).
 */
public protocol GLSAnimatable: class {
    
    var animations:[GLSAnimator] { get set }
    
    func updateAnimations(_ dt:CGFloat)
}

///Updates the animations on a GLSAnimatable object.
///The instance method on GLSAnimatable (added by the
///following protocol extension) simply calls this method
///because it's possible for classes to need to define
///custom logic for updating animations in addition
///to actually updating their animations, so having
///this as a separate function adheres to the DRY principle.
public func updateAnimationsFor(_ animatable:GLSAnimatable, dt:CGFloat) {
    var indicesToRemove:[Int] = []
    
    for iii in 0..<animatable.animations.count {
        
        animatable.animations[iii].update(dt)
        
        if (animatable.animations[iii].isFinished) {
            animatable.animations[iii].endAnimation()
            indicesToRemove.append(iii)
        }//finished
        
    }//check if finished
    
    let count = indicesToRemove.count
    for i in 0..<count {
        let j = count - i - 1
        animatable.animations.remove(at: indicesToRemove[j])
    }//remove animations
}

extension GLSAnimatable {
    
    // MARK: - Handling Animations
    
    public func updateAnimations(_ dt:CGFloat) {
        updateAnimationsFor(self, dt: dt)
    }//update animations
    
    public func stopAnimations() {
        self.animations.removeAll(keepingCapacity: false)
    }//stop animations from animating
    
    // MARK: - Adding Animations
    
    public func add1Animation(_ start:CGFloat, end:CGFloat, function:@escaping (CGFloat) -> ()) {
        guard GLSNode.animationInstance.inAnimationBlock else {
            return
        }
        //Usually called from didSet property observers, so
        //we need to reset the value to its proper starting value.
        //Also we have to make sure it's not in animating-mode
        //or else it will infinitely recurse.
        GLSNode.runWithoutAnimating() {
            function(start)
        }
        let animation = GLSFloatAnimator(mode: GLSNode.animationInstance.animationMode, duration: GLSNode.animationInstance.animationDuration, start: start, end: end, handler: function)
        self.animations.append(animation)
    }//add animation-1
    
    public func add2Animation(_ start:CGPoint, end:CGPoint, function:@escaping (CGPoint) -> ()) {
        guard GLSNode.animationInstance.inAnimationBlock else {
            return
        }
        GLSNode.runWithoutAnimating() {
            function(start)
        }
        let animation = GLSPointAnimator(mode: GLSNode.animationInstance.animationMode, duration: GLSNode.animationInstance.animationDuration, start: start, end: end, handler: function)
        self.animations.append(animation)
    }//add animation-2
    
    public func add3Animation(_ start:SCVector3, end:SCVector3, function:@escaping (SCVector3) -> ()) {
        guard GLSNode.animationInstance.inAnimationBlock else {
            return
        }
        GLSNode.runWithoutAnimating() {
            function(start)
        }
        let animation = GLSVector3Animator(mode: GLSNode.animationInstance.animationMode, duration: GLSNode.animationInstance.animationDuration, start: start, end: end, handler: function)
        self.animations.append(animation)
    }//add animation-3
    
    public func add4Animation(_ start:SCVector4, end:SCVector4, function:@escaping (SCVector4) -> ()) {
        guard GLSNode.animationInstance.inAnimationBlock else {
            return
        }
        GLSNode.runWithoutAnimating() {
            function(start)
        }
        let animation = GLSVector4Animator(mode: GLSNode.animationInstance.animationMode, duration: GLSNode.animationInstance.animationDuration, start: start, end: end, handler: function)
        self.animations.append(animation)
    }//add animation-3
    
}
