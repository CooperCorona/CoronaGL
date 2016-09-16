//
//  GLSDoubleSprite.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 4/27/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

open class GLSDoubleSprite: GLSSprite, DoubleBuffered {
   
    public struct DoubleVertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var texture1:(GLfloat, GLfloat) = (0.0, 0.0)
        var texture2:(GLfloat, GLfloat) = (0.0, 0.0)
    }
    
    open var firstTexture:CCTexture?  = nil {
        didSet {
            self.bufferIsDirty = true
        }
    }
    open var secondTexture:CCTexture? = nil {
        didSet {
            self.bufferIsDirty = true
        }
    }
    
    open var doubleVertices = [DoubleVertex(), DoubleVertex(), DoubleVertex(), DoubleVertex(), DoubleVertex(), DoubleVertex()]
    
    open let doubleProgram = ShaderHelper.programDictionaryForString("Double Shader")!
    open var buffer:GLSFrameBuffer
    open var shouldRedraw = false
    open fileprivate(set) var bufferIsDirty = false
    
    
    public init(size:CGSize, firstTexture:CCTexture?, secondTexture:CCTexture?) {
        
        self.buffer = GLSFrameBuffer(size: size)
        
        super.init(position: CGPoint.zero, size: size, texture: self.buffer.ccTexture)
        
        self.firstTexture = firstTexture
        self.secondTexture = secondTexture
        
        self.setQuadForTexture()
    }//initialize
    
    
    override open func setQuadForTexture() {
    
        super.setQuadForTexture()
        
        let sizeAsPoint = self.contentSize.getCGPoint()
        let frame1 = self.firstTexture?.frame  ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        let frame2 = self.secondTexture?.frame ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        let frame1SizeAsPoint = frame1.size.getCGPoint()
        let frame2SizeAsPoint = frame2.size.getCGPoint()
        for iii in 0..<self.doubleVertices.count {
            let curPoint = TexturedQuad.pointForIndex(iii)
            self.doubleVertices[iii].position = (curPoint * sizeAsPoint).getGLTuple()
            self.doubleVertices[iii].texture1 = (curPoint * frame1SizeAsPoint + frame1.origin).getGLTuple()
            self.doubleVertices[iii].texture2 = (curPoint * frame2SizeAsPoint + frame2.origin).getGLTuple()
        }
    
    }//apply texture to vertices
    
    open func renderToTexture() {
        
        self.framebufferStack?.pushGLSFramebuffer(buffer: self.buffer)
        self.buffer.bindClearColor()
        
        self.doubleProgram.use()
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<DoubleVertex>.size * self.doubleVertices.count, self.doubleVertices, GLenum(GL_DYNAMIC_DRAW))
        
        self.doubleProgram.uniformMatrix4fv("u_Projection", matrix: self.projection)
        
        glUniform1i(self.doubleProgram["u_TextureInfo1"], 0)
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.firstTexture?.name ?? 0)
        
        glUniform1i(self.doubleProgram["u_TextureInfo2"], 1)
        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.secondTexture?.name ?? 0)
        
        glActiveTexture(GLenum(GL_TEXTURE0))
        
        self.doubleProgram.enableAttributes()
        self.doubleProgram.bridgeAttributesWithSizes([2, 2, 2], stride: MemoryLayout<DoubleVertex>.size)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.doubleVertices.count))
        
        self.doubleProgram.disable()
        
        self.framebufferStack?.popFramebuffer()
        
        self.bufferIsDirty = false
    }//render to texture
    
}
