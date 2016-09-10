//
//  NoiseTexture2D.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 5/27/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

import GLKit
import CoronaConvenience
import CoronaStructures

public class Noise3DTexture2D: NSObject {
    
    public let noise:NoiseArray3D
    public private(set) var noiseTexture:GLuint = 0
    public private(set) var permutationTexture:GLuint = 0
    
    public init(noise:NoiseArray3D) {
        
        self.noise = noise
        
        glGenTextures(1, &self.noiseTexture)
        
        let texEnum = GLenum(GL_TEXTURE_2D)
        glBindTexture(texEnum, self.noiseTexture)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
        
        var colorArray:[GLubyte] = []
        for color in self.noise.gradients {
            //Clamped to range [0.0, 1.0]
            let clampedColor = color / 2.0 + 0.5
            colorArray.append(GLubyte(clampedColor.r * 255.0))
            colorArray.append(GLubyte(clampedColor.g * 255.0))
            colorArray.append(GLubyte(clampedColor.b * 255.0))
            colorArray.append(255)//Alpha
        }
        
        glTexImage2D(texEnum, 0, GLint(GL_RGBA), GLsizei(NoiseArray3D.totalCount), 1, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), colorArray)
        
        
        glGenTextures(1, &self.permutationTexture)
        glBindTexture(texEnum, self.permutationTexture)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        let nCount = NoiseArray3D.totalCount
        var permutationArray:[GLubyte] = []
//        for perm in self.noise.permutations {
        for iii in 0..<nCount {
            let index = iii & 255
            let nextIndex = (index + 1) & 255
            let perm = self.noise.permutations[index]
            let nextPerm = self.noise.permutations[nextIndex]
            
            let doubleIndex = (2 * index) & 255
            let nextDoubleIndex = (doubleIndex + 1) & 255
            let doublePerm = self.noise.permutations[doubleIndex]
            let nextDoublePerm = self.noise.permutations[nextDoubleIndex]
            //Clamped to range [0.0, 1.0]
            permutationArray.append(GLubyte(perm))
            permutationArray.append(GLubyte(nextPerm))
            permutationArray.append(GLubyte(doublePerm))
            permutationArray.append(GLubyte(nextDoublePerm))//Alpha
        }
        
        glTexImage2D(texEnum, 0, GLint(GL_RGBA), GLsizei(nCount), 1, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), permutationArray)
        
        super.init()

    }//initialize
    
    public convenience init(seed:UInt32) {
        let noise = NoiseArray3D(seed: seed)
        self.init(noise: noise)
    }
    
    ///Initializes with a random seed.
    public convenience override init() {
        self.init(seed: arc4random())
    }
    
    
    public func debugQuickLookObject() -> AnyObject {
        return "Seed = \(self.noise.seed)"
    }
}


public class Noise2DTexture2D: NSObject {
    
    public let noise:NoiseArray2D
    public private(set) var noiseTexture:GLuint = 0
    public private(set) var permutationTexture:GLuint = 0
    
    public init(noise:NoiseArray2D) {
        
        self.noise = noise
        
        glGenTextures(1, &self.noiseTexture)
        
        let texEnum = GLenum(GL_TEXTURE_2D)
        glBindTexture(texEnum, self.noiseTexture)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
        
        var colorArray:[GLubyte] = []
        for color in self.noise.gradients {
            //Clamped to range [0.0, 1.0]
            let clampedColor = color / 2.0 + 0.5
            colorArray.append(GLubyte(clampedColor.x * 255.0))
            colorArray.append(GLubyte(clampedColor.y * 255.0))
            colorArray.append(0)
            colorArray.append(255)//Alpha
        }
        
        glTexImage2D(texEnum, 0, GLint(GL_RGBA), GLsizei(NoiseArray2D.totalCount), 1, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), colorArray)
        
        
        glGenTextures(1, &self.permutationTexture)
        glBindTexture(texEnum, self.permutationTexture)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glTexParameteri(texEnum, GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        let nCount = NoiseArray2D.totalCount
        var permutationArray:[GLubyte] = []
        //        for perm in self.noise.permutations {
        for iii in 0..<nCount {
            let index = iii & 255
            let nextIndex = (index + 1) & 255
            let perm = self.noise.permutations[index]
            let nextPerm = self.noise.permutations[nextIndex]
            //Clamped to range [0.0, 1.0]
            permutationArray.append(GLubyte(perm))
            permutationArray.append(GLubyte(nextPerm))
            permutationArray.append(0)
            permutationArray.append(255)//Alpha
        }
        
        glTexImage2D(texEnum, 0, GLint(GL_RGBA), GLsizei(nCount), 1, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), permutationArray)
        
        super.init()
        
    }//initialize
    
    public convenience init(seed:UInt32) {
        let noise = NoiseArray2D(seed: seed)
        self.init(noise: noise)
    }
    
    ///Initializes with a random seed.
    public convenience override init() {
        self.init(seed: arc4random())
    }
}
