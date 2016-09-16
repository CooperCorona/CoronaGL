//
//  NoiseFadeAnimation.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 8/12/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaStructures

open class NoiseFadeAnimation: NSObject {
    
    // MARK: - Properties
    
    fileprivate let entranceHelper:GLSAnimationHelper
    fileprivate let exitHelper:GLSAnimationHelper
    
    open let sprite:GLSPerlinNoiseSprite
    open let duration:CGFloat
    open let appearing:Bool
    open fileprivate(set) var entering = true
    open var gradient:ColorGradient1D {
        let colors = [SCVector4(x: 1.0, y: 1.0, z: 1.0, w: 0.0), SCVector4.whiteColor]
        //        let colors = [SCVector4(x: 0.0, y: 0.0, z: 0.0, w: 0.0), SCVector4.blackColor]
        let weights:[CGFloat]
        let smoothed = false
        
        switch (self.appearing, self.entering) {
        case (false, true):
            weights = [0.0, self.entranceHelper.realTime]
        case (false, false):
            weights = [self.exitHelper.realTime, 1.0]
        case (true, true):
            weights = [1.0 - self.entranceHelper.realTime, 1.0]
        case (true, false):
            weights = [0.0, 1.0 - self.exitHelper.realTime]
        }
        
        return ColorGradient1D(colors: colors, weights: weights, smoothed: smoothed)
    }
    
    open var completionHandler:(() -> Void)? = nil
    
    open var isFinished:Bool { return self.exitHelper.isFinished }
    
    // MARK: - Setup
    
    public init(sprite:GLSPerlinNoiseSprite, duration:CGFloat, appearing:Bool) {
        self.sprite = sprite
        self.duration = duration
        self.appearing = appearing
        
        self.entranceHelper = GLSAnimationHelper(mode: .easeIn, duration: self.duration / 2.0)
        self.exitHelper     = GLSAnimationHelper(mode: .easeOut, duration: self.duration / 2.0)
        
        super.init()
    }
    
    // MARK: - Logic
    
    open func update(_ dt:CGFloat) {
        if self.entering {
            self.entranceHelper.update(dt)
            if self.entranceHelper.isFinished {
                self.entering = false
            }
        } else {
            self.exitHelper.update(dt)
        }
        let grad = self.gradient
        self.sprite.gradient = GLGradientTexture2D(gradient: grad)
        self.sprite.renderToTexture()
    }
    
}
