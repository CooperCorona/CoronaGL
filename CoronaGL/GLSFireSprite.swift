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
import CoronaStructures

///Uses 2D Noise to create and animate a colorable fire.
open class GLSFireSprite: GLSSprite, DoubleBuffered {
    
    public enum NoiseType {
        case `default`
        case fractal
    }
    
    public struct FireVertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var noiseTexture:(GLfloat, GLfloat) = (0.0, 0.0)
    }
    
    // MARK: - Properties
    
    ///The desired noise gradients.
    open let noiseTexture:Noise2DTexture2D
    
    ///The colors to use for the fire (0.0 is the bottom, 1.0 is the top).
    open let gradient:GLGradientTexture2D
    
    open let buffer:GLSFrameBuffer
    
    open var noiseType:NoiseType = .default {
        didSet {
            switch self.noiseType {
            case .default:
                self.fireProgram = ShaderHelper.programDictionaryForString("Fire Shader")!
            case .fractal:
                self.fireProgram = ShaderHelper.programDictionaryForString("Fractal Fire Shader")!
            }
            if oldValue != self.noiseType {
                self.bufferIsDirty = true
            }
        }
    }
    public private(set) var fireProgram = ShaderHelper.programDictionaryForString("Fire Shader")!
    open let fireVertices = TexturedQuadVertices(vertex: FireVertex())
    
    ///How much noise (how many peaks/troughs).
    open var noiseSize:CGFloat = 1.0 {
        didSet {
            self.noiseSizeChanged()
            self.bufferIsDirty = true
        }
    }
    ///What to divide the noise by (to help get noise in desired range).
    open var noiseDivisor:CGFloat = 0.7 {
        didSet {
            self.bufferIsDirty = true
        }
    }
    ///The baseline of the fire.
    open var noiseCenter:CGFloat = 0.5 {
        didSet {
            self.bufferIsDirty = true
        }
    }
    ///How much the noise should offset from the baseline.
    open var noiseRange:CGFloat = 1.0 {
        didSet {
            self.bufferIsDirty = true
        }
    }
    ///Offset into the fire (Y-Values are animated).
    open var offset = CGPoint.zero {
        didSet {
            if self.shouldRedraw && !(self.offset ~= oldValue) {
                self.renderToTexture()
            }
            let x = self.offset.x.truncatingRemainder(dividingBy: CGFloat(self.period.x))
            let y = self.offset.y.truncatingRemainder(dividingBy: CGFloat(self.period.y))
            self.offset = CGPoint(x: x, y: y)
            self.bufferIsDirty = true
        }
    }
    ///How fast the offset is changing.
    open var offsetVelocity = CGPoint.zero
    ///The point at which the noise starts repeating.
    ///If you set it equal to the noise size (or some
    ///divisor thereof), the sprite becomes tileable.
    open var period:(x:Int, y:Int) = (255, 255) {
        didSet {
            let x = self.offset.x.truncatingRemainder(dividingBy: CGFloat(self.period.x))
            let y = self.offset.y.truncatingRemainder(dividingBy: CGFloat(self.period.y))
            self.offset = CGPoint(x: x, y: y)
            self.bufferIsDirty = true
        }
    }
    
    ///Whether the fire should attenuate the alpha near the top.
    ///Note that this causes the fire to appear smaller than it actually is,
    ///because the top is invisible (alpha == 0.0).
    open var attenuateAlpha = true
    
    ///Whether the sprite should invoke renderToTexture() when the offset is changed.
    open var shouldRedraw = false
    open fileprivate(set) var bufferIsDirty = false
    
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
    open func renderToTexture() {
        self.framebufferStack?.pushGLSFramebuffer(buffer: self.buffer)
        self.buffer.bindClearColor()
        
        self.fireProgram.use()
        glBufferData(GLenum(GL_ARRAY_BUFFER), self.fireVertices.size, self.fireVertices.vertices, GLenum(GL_STATIC_DRAW))
        self.fireProgram.uniformMatrix4fv("u_Projection", matrix: self.projection)
        
        self.fireProgram.uniform2f("u_Offset", value: self.offset)
        self.fireProgram.uniform1f("u_NoiseDivisor", value: self.noiseDivisor)
        self.fireProgram.uniform1f("u_NoiseCenter", value: self.noiseCenter)
        self.fireProgram.uniform1f("u_NoiseRange", value: self.noiseRange)
        self.fireProgram.uniform1f("u_AttenuateAlpha", value: self.attenuateAlpha ? 1.0 : 0.0)
        glUniform2i(self.fireProgram["u_Period"], GLint(self.period.x), GLint(self.period.y))
        
        self.pushTexture(self.noiseTexture.permutationTexture, atLocation: self.fireProgram["u_PermutationInfo"])
        self.pushTexture(self.noiseTexture.noiseTexture, atLocation: self.fireProgram["u_NoiseTextureInfo"])
        self.pushTexture(self.gradient.textureName, atLocation: self.fireProgram["u_GradientInfo"])
        
        self.fireProgram.enableAttributes()
        self.fireProgram.bridgeAttributesWithSizes([2, 2], stride: self.fireVertices.stride)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.fireVertices.count))
        
        self.fireProgram.disable()
        self.popTextures()
        
        self.framebufferStack?.popFramebuffer()
        
        self.bufferIsDirty = false
    }//render to texture
    
    fileprivate func noiseSizeChanged() {
        self.fireVertices.iterateWithHandler() { index, vertex in
            let curPos = TexturedQuad.pointForIndex(index)
            vertex.noiseTexture = (GLfloat(curPos.x * self.noiseSize), GLfloat(curPos.y))
            return
        }
    }
    
    open override func update(_ dt: CGFloat) {
        super.update(dt)
        
        self.offset += self.offsetVelocity * dt
    }
    
}
