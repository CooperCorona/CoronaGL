//
//  GLSFrameSprite.swift
//  Gravity
//
//  Created by Cooper Knaak on 5/22/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif


open class GLSFrameSprite: GLSSprite {
   
    // MARK: - Types
    
    public enum IncrementStyle {
        case manual
        case automatic(CGFloat)
        case automaticBackwards(CGFloat)
        case automaticReverse(CGFloat)
    }
    
    // MARK: - Properties
    
    open let textures:[CCTexture?]
    open let sizes:[CGSize]
    
    open var incrementStyle = IncrementStyle.manual {
        didSet {
            switch self.incrementStyle {
            case .automatic:
                self.frameDelta = 1
            case .automaticBackwards:
                self.frameDelta = -1
            case .automaticReverse:
                if (self.textureIndex >= self.textures.count - 1) {
                    self.frameDelta = -1
                } else {
                    self.frameDelta = +1
                }
            default:
                self.frameDelta = 0
            }
        }
    }
    open fileprivate(set) var incrementCount:CGFloat = 0.0
    ///What to increment the frame index by.
    fileprivate var frameDelta = 0
    
    open fileprivate(set) var textureIndex = 0
    open var currentTexture:CCTexture? { return self.textures[self.textureIndex] }
    
    // MARK: - Setup
    
    public init?(sizes:[CGSize], textures:[CCTexture?]) {
        
        self.sizes      = sizes
        self.textures   = textures
        
        let initialSize = self.sizes.count > 0 ? self.sizes[0] : CGSize.zero
        let initialTex  = self.textures.count > 0 ? self.textures[0] : nil
        
        super.init(position: CGPoint.zero, size: initialSize, texture: initialTex)
        
        if (sizes.count <= 0 || sizes.count != textures.count) {
            return nil
        }
        
        self.textureIndexChanged()
    }//initialize
    
    public convenience init!(size:CGSize, textures:[CCTexture?]) {
        
        var sizes = [size]
        for _ in 1..<textures.count {
            sizes.append(size)
        }
        
        self.init(sizes: sizes, textures: textures)
        
    }//initialize
    
    // MARK: - Logic
    
    open override func update(_ dt: CGFloat) {
        super.update(dt)
        
        if (self.textures.count > 1) {
            self.updateFrame(dt)
        }
    }//update
    
    open func updateFrame(_ dt:CGFloat) {
        
        switch self.incrementStyle {
        case let .automatic(frequency):
            
            if (self.incrementFrame(dt, frequency: frequency)) {
                
                if (self.textureIndex >= self.textures.count) {
                    self.textureIndex = 0
                }
                
                self.textureIndexChanged()
            }
            
        case let .automaticBackwards(frequency):
            
            if (self.incrementFrame(dt, frequency: frequency)) {
                
                if (self.textureIndex < 0) {
                    self.textureIndex = self.textures.count - 1
                }
                
                self.textureIndexChanged()
            }
            
        case let .automaticReverse(frequency):
            
            if (self.incrementFrame(dt, frequency: frequency)) {
                
                if (self.textureIndex == 0) {
//                    self.textureIndex = self.textures.count - 1
//                    self.textureIndex   = 0
                    self.frameDelta     = +1
                } else if (self.textureIndex == self.textures.count - 1) {
//                    self.textureIndex = 0
//                    self.textureIndex   = self.textures.count - 1
                    self.frameDelta     = -1
                }
                
                self.textureIndexChanged()
            }
            
        default:
            break
        }
    }
    
    fileprivate func incrementFrame(_ dt:CGFloat, frequency:CGFloat) -> Bool {
        
        self.incrementCount += dt
        
        if (self.incrementCount >= frequency) {
            self.textureIndex   += self.frameDelta
            self.incrementCount -= frequency
            return true
        }
        
        return false
    }
    
    fileprivate func textureIndexChanged() -> Bool {
        
        if (self.textureIndex < 0 || self.textureIndex >= self.textures.count) {
            return false
        }
        
        self.texture        = self.textures[self.textureIndex]
        self.contentSize    = self.sizes[self.textureIndex]
        
        TexturedQuad.setPosition(CGRect(x: 0.0, y: 0.0, width: self.contentSize.width, height: self.contentSize.height), ofVertices: &self.vertices)
        
        if let frame = self.texture?.frame {
            TexturedQuad.setTexture(frame, ofVertices: &self.vertices)
        }
        
        self.verticesAreDirty = true
        
        return true
    }//configure vertices and content size
    
}
