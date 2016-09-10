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

public class GLSDoubleSprite: GLSSprite, DoubleBuffered {
   
    public struct DoubleVertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var texture1:(GLfloat, GLfloat) = (0.0, 0.0)
        var texture2:(GLfloat, GLfloat) = (0.0, 0.0)
    }
    
    public class DoubleShaderProgram {
        
        public var vertexBuffer:GLuint = 0
        public let program:GLuint
        public let u_Projection:GLint
        public let u_ModelMatrix:GLint
        /*public let u_TintColor:GLint
        public let u_TintIntensity:GLint
        public let u_ShadeColor:GLint
        public let u_Alpha:GLint*/
        public let u_TextureInfo1:GLint
        public let u_TextureInfo2:GLint
        public let a_Position:GLint
        public let a_Texture1:GLint
        public let a_Texture2:GLint
        
        public init() {
            glGenBuffers(1, &self.vertexBuffer)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.vertexBuffer)
            
            self.program            = ShaderHelper.programForString("Double Shader")!
            self.u_Projection       = glGetUniformLocation(self.program, "u_Projection")
            self.u_ModelMatrix      = glGetUniformLocation(self.program, "u_ModelMatrix")
            /*self.u_TintColor        = glGetUniformLocation(self.program, "u_TintColor")
            self.u_TintIntensity    = glGetUniformLocation(self.program, "u_TintIntensity")
            self.u_ShadeColor       = glGetUniformLocation(self.program, "u_ShadeColor")
            self.u_Alpha            = glGetUniformLocation(self.program, "u_Alpha")*/
            self.u_TextureInfo1     = glGetUniformLocation(self.program, "u_TextureInfo1")
            self.u_TextureInfo2     = glGetUniformLocation(self.program, "u_TextureInfo2")
            self.a_Position         = glGetAttribLocation( self.program, "a_Position")
            self.a_Texture1         = glGetAttribLocation( self.program, "a_Texture1")
            self.a_Texture2         = glGetAttribLocation( self.program, "a_Texture2")
        }
        
        deinit {
            glDeleteBuffers(1, &self.vertexBuffer)
            self.vertexBuffer = 0
        }
    }
    
    public var firstTexture:CCTexture?  = nil {
        didSet {
            self.bufferIsDirty = true
        }
    }
    public var secondTexture:CCTexture? = nil {
        didSet {
            self.bufferIsDirty = true
        }
    }
    
    public var doubleVertices = [DoubleVertex(), DoubleVertex(), DoubleVertex(), DoubleVertex(), DoubleVertex(), DoubleVertex()]
    
    public let doubleProgram = DoubleShaderProgram()
    public var buffer:GLSFrameBuffer
    public var shouldRedraw = false
    public private(set) var bufferIsDirty = false
    
    
    public init(size:CGSize, firstTexture:CCTexture?, secondTexture:CCTexture?) {
        
        self.buffer = GLSFrameBuffer(size: size)
        
//        super.init(position: CGPoint.zero, size: size)
//        super.init(size: size, texture: firstTexture)
        super.init(position: CGPoint.zero, size: size, texture: firstTexture)
        
        self.firstTexture = firstTexture
        self.secondTexture = secondTexture
        
        self.setQuadForTexture()
    }//initialize
    
    
    override public func setQuadForTexture() {
    
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
    
    public func renderToTexture() {
        
        self.framebufferStack?.pushGLSFramebuffer(self.buffer)
        self.buffer.bindClearColor()
        
        glUseProgram(self.doubleProgram.program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.doubleProgram.vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), sizeof(DoubleVertex) * self.doubleVertices.count, self.doubleVertices, GLenum(GL_DYNAMIC_DRAW))
        
        //        let proj = GLSUniversalRenderer.sharedInstance.projection
        let proj = self.projection
        glUniformMatrix4fv(self.doubleProgram.u_Projection, 1, 0, proj.values)
        
        let model = SCMatrix4()
        glUniformMatrix4fv(self.doubleProgram.u_ModelMatrix, 1, 0, model.values)
        
        
        glUniform1i(self.doubleProgram.u_TextureInfo1, 0)
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.firstTexture?.name ?? 0)
        
        glUniform1i(self.doubleProgram.u_TextureInfo2, 1)
        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.secondTexture?.name ?? 0)
        
        glActiveTexture(GLenum(GL_TEXTURE0))
        
        
        let stride = sizeof(DoubleVertex)
        self.bridgeAttribute(self.doubleProgram.a_Position, size: 2, stride: stride, position: 0)
        self.bridgeAttribute(self.doubleProgram.a_Texture1, size: 2, stride: stride, position: 2)
        self.bridgeAttribute(self.doubleProgram.a_Texture2, size: 2, stride: stride, position: 4)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.doubleVertices.count))
        
        glDisableVertexAttribArray(GLuint(self.doubleProgram.a_Position))
        glDisableVertexAttribArray(GLuint(self.doubleProgram.a_Texture1))
        glDisableVertexAttribArray(GLuint(self.doubleProgram.a_Texture2))
        
        self.framebufferStack?.popFramebuffer()
        
        self.bufferIsDirty = false
    }//render to texture
    
}
