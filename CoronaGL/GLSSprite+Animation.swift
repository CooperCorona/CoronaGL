//
//  GLSSprite+Animation.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 2/1/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaConvenience
import CoronaStructures

// MARK: - Common Animations
///Defines methods that affect the transform
///to achieve common animations. Invoking them
///outside of GLSNode.animate will cause the
///effects to happen instantly and as such should
///not be used.
extension GLSSprite {

    /**
     Wipes out the sprite **in** a direction. Wiping appears as
     if a rectangle covers the sprite by moving in a given
     direction. However, instead of seeing something in
     front of the sprite, you see the background.
     - parameter direction: The direction in which the sprite wipes.
     The animation starts **in** the opposite of direction and moves in direction.
    */
    public func wipeOut(direction:Direction2D) {
        switch direction {
        case .Right:
            self.runWithoutAnimating() { self.move(anchor: CGPoint(x: 1.0, y: 0.5)) }
            self.scaleX = 0.0
            self.textureFrame = CGRect(x: 1.0, y: 0.0, width: 0.0, height: 1.0)
        case .Left:
            self.runWithoutAnimating() { self.move(anchor: CGPoint(x: 0.0, y: 0.5)) }
            self.scaleX = 0.0
            self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1.0)
        case .Up:
            self.runWithoutAnimating() { self.move(anchor: CGPoint(x: 0.5, y: 1.0)) }
            self.scaleY = 0.0
            self.textureFrame = CGRect(x: 0.0, y: 1.0, width: 1.0, height: 0.0)
        case .Down:
            self.runWithoutAnimating() { self.move(anchor: CGPoint(x: 0.5, y: 0.0)) }
            self.scaleY = 0.0
            self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 0.0)
        }
    }
    
    /**
     Wipes in the sprite **from** a direction. For a description
     of wiping, see wipeOut.
     - parameter direction: The direction **from** which the sprite wipes.
     The animation starts in direction and moves in the opposite direction.
     */
    public func wipeIn(direction:Direction2D) {
        //Components that are 0 become 0.5 (the middle. 1 - (1 - 0) * 0.5 = 1 - 0.5 = 0.5
        //and components that are 1 remain 1.0 (1 - (1 - 1) * 0.5 = 1 - 0 * 0.5 = 1 - 0 = 0.0
        let anchor = 1.0 - (1.0 - direction.vector) * 0.5
        self.runWithoutAnimating() { self.move(anchor: anchor) }
        switch direction {
        case .Right:
            self.runWithoutAnimating { self.textureFrame = CGRect(x: 1.0, y: 0.0, width: 0.0, height: 1.0) }
            self.scaleX = 1.0
        case .Left:
            self.runWithoutAnimating { self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1.0) }
            self.scaleX = 1.0
        case .Up:
            self.runWithoutAnimating { self.textureFrame = CGRect(x: 0.0, y: 1.0, width: 1.0, height: 0.0) }
            self.scaleY = 1.0
        case .Down:
            self.runWithoutAnimating { self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 0.0) }
            self.scaleY = 1.0
        }
        self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    }
    
    /**
     Slides out the sprite **in** a direction. Sliding appears as
     if the sprite's position moves behind a rectangle. However,
     instead of seeing something in front of the sprite, you see the background.
     - parameter direction: The direction **in** which the sprite slides.
     The animation starts in the opposite of direction and moves in direction.
     */
    public func slideOut(direction:Direction2D) {
        switch direction {
        case .Right:
            self.runWithoutAnimating() { self.move(anchor: CGPoint(x: 1.0, y: 0.5)) }
            self.scaleX = 0.0
            self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1.0)
        case .Left:
            self.runWithoutAnimating() { self.move(anchor: CGPoint(x: 0.0, y: 0.5)) }
            self.scaleX = 0.0
            self.textureFrame = CGRect(x: 1.0, y: 0.0, width: 0.0, height: 1.0)
        case .Up:
            self.runWithoutAnimating() { self.move(anchor: CGPoint(x: 0.5, y: 1.0)) }
            self.scaleY = 0.0
            self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 0.0)
        case .Down:
            self.runWithoutAnimating() { self.move(anchor: CGPoint(x: 0.5, y: 0.0)) }
            self.scaleY = 0.0
            self.textureFrame = CGRect(x: 0.0, y: 1.0, width: 1.0, height: 0.0)
        }
    }
    
    /**
     Slides in the sprite **from** a direction. For a description
     of sliding, see slideOut.
     - parameter direction: The direction **from** which the sprite slides.
     The animation starts in direction and moves in the opposite direction.
     */
    public func slideIn(direction:Direction2D) {
        //Um. Components that are 0 become 0.5 (the middle. 1 - (1 - 0) * 0.5 = 1 - 0.5 = 0.5
        //and components that are 1 remain 1.0 (1 - (1 - 1) * 0.5 = 1 - 0 * 0.5 = 1 - 0 = 0.0
        let anchor = 1.0 - (1.0 - direction.vector) * 0.5
        self.runWithoutAnimating() { self.move(anchor: anchor) }
        switch direction {
        case .Right:
            self.runWithoutAnimating { self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1.0) }
            self.scaleX = 1.0
        case .Left:
            self.runWithoutAnimating { self.textureFrame = CGRect(x: 1.0, y: 0.0, width: 0.0, height: 1.0) }
            self.scaleX = 1.0
        case .Up:
            self.runWithoutAnimating { self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 0.0) }
            self.scaleY = 1.0
        case .Down:
            self.runWithoutAnimating { self.textureFrame = CGRect(x: 0.0, y: 1.0, width: 1.0, height: 0.0) }
            self.scaleY = 1.0
        }
        self.textureFrame = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    }
    
}
