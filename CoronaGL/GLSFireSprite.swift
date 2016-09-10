//
//  GLSFireSprite.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 6/1/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience

///Uses 2D Noise to create and animate a colorable fire.
public class GLSFireSprite: GLSSprite, DoubleBuffered {
    
    // MARK: - Types
    
    public class FireProgram {
        
        let program:GLuint
        let attributeBridger:GLAttributeBridger
        let u_Projection:GLint
        let u_Offset:GLint
        let u_NoiseDivisor:GLint
        let u_NoiseCenter:GLint
        let u_NoiseRange:GLint
        let u_AttenuateAlpha:GLint
        let u_NoiseTextureInfo:GLint
        let u_PermutationInfo:GLint
        let u_GradientInfo:GLint
        let a_Position:GLint
        let a_NoiseTexture:GLint
        
        init() {
            let program = ShaderHelper.programForString("Fire Shader")!
            
            self.u_Projection       = glGetUniformLocation(program, "u_Projection")
            self.u_NoiseTextureInfo = glGetUniformLocation(program, "u_NoiseTextureInfo")
            self.u_PermutationInfo  = glGetUniformLocation(program, "u_PermutationInfo")
            self.u_GradientInfo     = glGetUniformLocation(program, "u_GradientInfo")
            self.u_Offset           = glGetUniformLocation(program, "u_Offset")
            self.u_NoiseDivisor     = glGetUniformLocation(program, "u_NoiseDivisor")
            self.u_NoiseCenter      = glGetUniformLocation(program, "u_NoiseCenter")
            self.u_NoiseRange       = glGetUniformLocation(program, "u_NoiseRange")
            self.u_AttenuateAlpha   = glGetUniformLocation(program, "u_AttenuateAlpha")
            self.a_Position     = glGetAttribLocation(program, "a_Position")
            self.a_NoiseTexture = glGetAttribLocation(program, "a_NoiseTexture")
            
            self.program = program
            self.attributeBridger = GLAttributeBridger(program: program)
            
            let atts = [self.a_Position, self.a_NoiseTexture]
            self.attributeBridger.addAttributes(atts)
        }
        
    }
    
    public struct FireVertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var noiseTexture:(GLfloat, GLfloat) = (0.0, 0.0)
    }
    
    // MARK: - Properties
    
    ///The desired noise gradients.
    public let noiseTexture:Noise2DTexture2D
    
    ///The colors to use for the fire (0.0 is the bottom, 1.0 is the top).
    public let gradient:GLGradientTexture2D
    
    public let buffer:GLSFrameBuffer
    
    public let fireProgram = FireProgram()
    public let fireVertices = TexturedQuadVertices(vertex: FireVertex())
    
    ///How much noise (how many peaks/troughs).
    public var noiseSize:CGFloat = 1.0 {
        didSet {
            self.noiseSizeChanged()
            self.bufferIsDirty = true
        }
    }
    ///What to divide the noise by (to help get noise in desired range).
    public var noiseDivisor:CGFloat = 0.7 {
        didSet {
            self.bufferIsDirty = true
        }
    }
    ///The baseline of the fire.
    public var noiseCenter:CGFloat = 0.5 {
        didSet {
            self.bufferIsDirty = true
        }
    }
    ///How much the noise should offset from the baseline.
    public var noiseRange:CGFloat = 1.0 {
        didSet {
            self.bufferIsDirty = true
        }
    }
    ///Offset into the fire (Y-Values are animated).
    public var offset = CGPoint.zero {
        didSet {
            if self.shouldRedraw && !(self.offset ~= oldValue) {
                self.renderToTexture()
            }
            
            self.bufferIsDirty = true
        }
    }
    ///How fast the offset is changing.
    public var offsetVelocity = CGPoint.zero
    
    ///Whether the fire should attenuate the alpha near the top.
    ///Note that this causes the fire to appear smaller than it actually is,
    ///because the top is invisible (alpha == 0.0).
    public var attenuateAlpha = true
    
    ///Whether the sprite should invoke renderToTexture() when the offset is changed.
    public var shouldRedraw = false
    public private(set) var bufferIsDirty = false
    
    /**
Initialize a Fire sprite.

- parameter size: The size of the sprite.
- parameter noise: The desired noise gradients.
- parameter gradient: The color gradient.
*/
    public init(size:CGSize, noise:Noise2DTexture2D, gradient:GLGradientTexture2D) {
        
        self.buffer = GLSFrameBuffer(size: size)
        self.noiseTexture = noise
        self.gradient = gradient
        
        let sap = size.getCGPoint()
        self.fireVertices.iterateWithHandler { index, vertex in
            let curPoint = TexturedQuad.pointForIndex(index)
            vertex.position = (curPoint * sap).getGLTuple()
            vertex.noiseTexture = curPoint.getGLTuple()
        }
        
        super.init(position: CGPoint.zero, size: size, texture: self.buffer.ccTexture)
        
    }
  
    ///Renders the fire to the background buffer
    public func renderToTexture() {
        
        self.framebufferStack?.pushGLSFramebuffer(self.buffer)
        self.buffer.bindClearColor()
        
        glUseProgram(self.fireProgram.program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.fireProgram.attributeBridger.vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), self.fireVertices.size, self.fireVertices.vertices, GLenum(GL_STATIC_DRAW))
        
        //        let proj = GLSUniversalRenderer.sharedInstance.projection
        let proj = self.projection
        glUniformMatrix4fv(self.fireProgram.u_Projection, 1, 0, proj.values)
        
        glUniform2f(self.fireProgram.u_Offset, GLfloat(self.offset.x), GLfloat(self.offset.y))
        glUniform1f(self.fireProgram.u_NoiseDivisor, GLfloat(self.noiseDivisor))
        glUniform1f(self.fireProgram.u_NoiseCenter, GLfloat(self.noiseCenter))
        glUniform1f(self.fireProgram.u_NoiseRange, GLfloat(self.noiseRange))
        glUniform1f(self.fireProgram.u_AttenuateAlpha, self.attenuateAlpha ? 1.0 : 0.0)
        
        self.pushTexture(self.noiseTexture.permutationTexture, atLocation: self.fireProgram.u_PermutationInfo)
        self.pushTexture(self.noiseTexture.noiseTexture, atLocation: self.fireProgram.u_NoiseTextureInfo)
        self.pushTexture(self.gradient.textureName, atLocation: self.fireProgram.u_GradientInfo)
        
        self.fireProgram.attributeBridger.enableAttributes()
        self.fireProgram.attributeBridger.bridgeAttributesWithSizes([2, 2], stride: self.fireVertices.stride)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.fireVertices.count))
        
        self.fireProgram.attributeBridger.disableAttributes()
        self.popTextures()
        
        self.framebufferStack?.popFramebuffer()
        
        self.bufferIsDirty = false
    }//render to texture
    
    private func noiseSizeChanged() {
        self.fireVertices.iterateWithHandler() { index, vertex in
            let curPos = TexturedQuad.pointForIndex(index)
            vertex.noiseTexture = (GLfloat(curPos.x * self.noiseSize), GLfloat(curPos.y))
            return
        }
    }
    
    public override func update(dt: CGFloat) {
        super.update(dt)
        
        self.offset += self.offsetVelocity * dt
    }
    
}
