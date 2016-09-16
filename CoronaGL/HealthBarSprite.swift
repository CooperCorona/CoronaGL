//
//  HealthBarSprite.swift
//  Gravity
//
//  Created by Cooper Knaak on 2/28/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

open class HealthBarSprite: NSObject {

    open let barSize:CGSize
    open let backSize:CGSize
    open let buffer:CGFloat
    
    open let backgroundSprite:GLSSprite
    open let foregroundSprite:GLSSprite
    open let outlineSprite:GLSSprite
    
    open var fullColor = SCVector3.greenColor
    open var emptyColor = SCVector3.redColor
    
    open var backgroundColor:SCVector3 {
        get {
            return self.backgroundSprite.shadeColor
        }
        set(color) {
            self.backgroundSprite.shadeColor = color
        }
    }

    open var outlineColor:SCVector3 {
        get {
            return self.outlineSprite.shadeColor
        }
        set(color) {
            self.outlineSprite.shadeColor = color
        }
    }
    
    open var position:CGPoint {
        get {
            return self.outlineSprite.position
        }
        set {
            self.outlineSprite.position = newValue
        }
    }
    
    public init(size:CGSize, buffer:CGFloat) {
        
        self.barSize = size
        self.backSize = self.barSize + buffer
        self.buffer = buffer
        
        let tex = CCTextureOrganizer.textureForString("White Tile")
        self.outlineSprite = GLSSprite(size: self.backSize, texture: tex)
        self.outlineSprite.shadeColor = SCVector3.lightGrayColor
        self.outlineSprite.title = "Bar Outline"
        
        self.backgroundSprite = GLSSprite(size: self.barSize, texture: tex)
        self.backgroundSprite.shadeColor = SCVector3.darkGrayColor
        self.backgroundSprite.title = "Bar Background"
        self.outlineSprite.addChild(self.backgroundSprite)
        
        self.foregroundSprite = GLSSprite(size: self.barSize, texture: tex)
        self.foregroundSprite.shadeColor = self.fullColor
        self.foregroundSprite.anchor = CGPoint(x: 0.0, y: 0.5)
        self.foregroundSprite.position = CGPoint(x: -self.barSize.width / 2.0, y: 0.0)
        self.foregroundSprite.title = "Bar Foreground"
        self.outlineSprite.addChild(self.foregroundSprite)
        
        super.init()
    }//initialize
    
    open func colorForPercent(_ percent:CGFloat) -> SCVector3 {
        return self.emptyColor + (self.fullColor - self.emptyColor) * percent
    }//color for percent
    
    open func applyPercent(_ percent:CGFloat) {
        let realPercent = min(max(percent, 0.0), 1.0)
        self.foregroundSprite.scaleX = realPercent
        self.foregroundSprite.shadeColor = self.colorForPercent(realPercent)
    }//apply percent
    
    open func animatePercent(_ percent:CGFloat, withDuration:CGFloat) {
        
        GLSNode.animateWithDuration(withDuration, mode: AnimationModes.easeInOut) { [unowned self] in
            self.applyPercent(percent)
        }
        
    }//animate percent
    
}
