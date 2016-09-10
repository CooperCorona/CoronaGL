//
//  GLGradientTexture2D.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 5/27/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

import GLKit

public class GLGradientTexture2D: NSObject {
    
    // MARK: - Properties
    public private(set) var gradient:ColorGradient1D
    public private(set) var textureName:GLuint = 0
    
    ///Controls whether texture repeats or clamps.
    ///*true* for Repeat (jump from 0.0 to 1.0 and vice-versa).
    ///*false* for Clamp (numbers below 0.0 become 0.0, and numbers above 1.0 become 1.0)
    public var repeats:Bool = false {
        didSet {
            glBindTexture(GLenum(GL_TEXTURE_2D), self.textureName)
            if self.repeats {
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
            } else {
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
            }
        }
    }
    
    // MARK: - Setup
    public init(gradient:ColorGradient1D) {
        
        self.gradient = gradient
        //Generate Texture
        
        glGenTextures(1, &self.textureName)
        
        let texEnum = GLenum(GL_TEXTURE_2D)
        glBindTexture(texEnum, self.textureName)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        
        /*
         *  The incongruities in the Perlin Sin Noise Shader appears
         *  to be caused by setting GL_TEXTURE_WRAP_S to GL_REPEAT.
         *  I have no idea why, because it seems to jump from 0.0
         *  to 0.5, instead of 0.99 like would be expected. Regardless,
         *  I am now setting the the property to GL_CLAMP_TO_EDGE. This
         *  gives the other advantage of allowing me to set the noiseDivisor
         *  property of GLSPerlinNoiseSprite to values below 0.7 (so I can
         *  achieve more drastic colors) without having annoying jumps from
         *  0.0 to 1.0 and vice-versa. I am adding a `repeat` property to
         *  reenable this functionality.
         */
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        glTexImage2D(texEnum, 0, GLint(GL_RGBA), GLsizei(self.gradient.size), 1, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), self.gradient.colorArray)
        
        super.init()
    }//initialize
    
    // MARK: - Quick Look Debug
    public func debugQuickLookObject() -> AnyObject {
        /*
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        
        for iii in 0..<256 {
        let r = self.colorArray[iii * 4]
        let g = self.colorArray[iii * 4 + 1]
        let b = self.colorArray[iii * 4 + 2]
        let a = self.colorArray[iii * 4 + 3]
        let color = UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(a) / 255.0)
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, CGRect(x: CGFloat(iii), y: 0.0, width: 1.0, height: size.height))
        }
        
        let im = UIGraphicsGetImageFromCurrentImageContext()
        CGContextRestoreGState(context)
        UIGraphicsEndImageContext()
        
        return im
        */
        return self.gradient.getImage()
    }
    
    // MARK: - Clean Up
    deinit {
        glDeleteTextures(1, &self.textureName)
        self.textureName = 0
    }
    
}