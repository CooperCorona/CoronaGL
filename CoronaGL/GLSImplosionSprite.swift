//
//  GLSImplosionSprite.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 11/26/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

open class GLSImplosionSprite: GLSSprite, DoubleBuffered {
    
    public enum ImplosionType {
        case Implosion
        case Explosion
    }
    
    public struct ImplosionVertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var texture:(GLfloat, GLfloat) = (0.0, 0.0)
        var implosionTexture:(GLfloat, GLfloat) = (0.0, 0.0)
    }
    
    open var implosionTexture:CCTexture? = nil {
        didSet {
            self.bufferIsDirty = true
        }
    }
    
    open var implosionStrength:CGFloat = 0.07 {
        didSet {
            if self.inAnimationBlock {
                self.add1Animation(oldValue, end: self.implosionStrength) { [unowned self] in self.implosionStrength = $0 }
                self.implosionStrength = oldValue
            }
        }
    }
    open var implosionPoint:CGPoint = CGPoint.zero {
        didSet {
            if self.inAnimationBlock {
                self.add2Animation(oldValue, end: self.implosionPoint) { [unowned self] in self.implosionPoint = $0 }
                self.implosionPoint = oldValue
            }
        }
    }
    open var implosionType:ImplosionType = .Implosion {
        didSet {
            self.bufferIsDirty = true
        }
    }
    
    private var implosionProgram = ShaderHelper.programDictionaryForString("Implosion Shader")!
    open let implosionVertices = TexturedQuadVertices<ImplosionVertex>(vertex: ImplosionVertex())
    
    private(set) open var buffer:GLSFrameBuffer
    open var bufferIsDirty = false
    open var shouldRedraw = true
    
    public init(size:CGSize, texture:CCTexture?) {
        self.implosionTexture = texture
        self.buffer = GLSFrameBuffer(size: size)
        let tFrame = texture?.frame ?? CGRect.zero
        self.implosionVertices.iterateWithHandler() { index, vertex in
            let p = TexturedQuad.pointForIndex(index)
            vertex.texture = tFrame.interpolate(p).getGLTuple()
            vertex.position = (p * size).getGLTuple()
            vertex.implosionTexture = p.getGLTuple()
        }
        super.init(position: CGPoint.zero, size: size, texture: self.buffer.ccTexture)
    }
    
    open func implosionTexturedChanged() {
        let tFrame = self.implosionTexture?.frame ?? CGRect.zero
        self.implosionVertices.iterateWithHandler() { index, vertex in
            let p = TexturedQuad.pointForIndex(index)
            vertex.texture = tFrame.interpolate(p).getGLTuple()
        }
    }
    
    open override func contentSizeChanged() {
        self.buffer = GLSFrameBuffer(size: self.contentSize)
        self.bufferIsDirty = true
        self.implosionVertices.iterateWithHandler() { index, vertex in
            vertex.position = TexturedQuad.pointForIndex(index).getGLTuple()
        }
    }
    
    open override func update(_ dt: CGFloat) {
        super.update(dt)
        
        if self.shouldRedraw && self.bufferIsDirty {
            self.renderToTexture()
        }
    }
    
    open func renderToTexture() {
        self.framebufferStack?.pushGLSFramebuffer(buffer: self.buffer)
        self.implosionProgram.use()
        self.implosionVertices.bufferDataWithVertexBuffer(self.implosionProgram.vertexBuffer)
        
        self.implosionProgram.uniformMatrix4fv("u_Projection", matrix: self.projection)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.implosionTexture?.name ?? 0)
        glUniform1i(self.implosionProgram["u_TextureInfo"], 0)
        self.implosionProgram.uniform1f("u_ImplosionStrength", value: self.implosionStrength)
        
        let scaledImplosionPoint = self.implosionPoint / self.contentSize.getCGPoint()
        self.implosionProgram.uniform2f("u_ImplosionPoint", value: scaledImplosionPoint)
        
        switch self.implosionType {
        case .Implosion:
            self.implosionProgram.uniform1f("u_IsImplosion", value: 1.0)
        case .Explosion:
            self.implosionProgram.uniform1f("u_IsImplosion", value: -1.0)
        }
        
        self.implosionProgram.enableAttributes()
        self.implosionProgram.bridgeAttributesWithSizes([2, 2, 2], stride: MemoryLayout<ImplosionVertex>.stride)
        self.implosionVertices.drawArrays()
        self.implosionProgram.disableAttributes()
        
        self.framebufferStack?.popFramebuffer()
    }
    
}
