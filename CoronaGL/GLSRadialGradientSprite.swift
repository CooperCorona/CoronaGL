//
//  GLSRadialGradientSprite.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 6/16/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

public class GLSRadialGradientSprite: GLSSprite, DoubleBuffered {
   
    class RadialGradientProgram: GLAttributeBridger {
        
        let u_Projection:GLint
        let u_GradientInfo:GLint
        let u_TextureInfo:GLint
        let a_Position:GLint
        let a_RadialTexture:GLint
        let a_Texture:GLint
        
        init() {
            let program = ShaderHelper.programForString("Radial Gradient Shader")!
            
            self.u_Projection   = glGetUniformLocation(program, "u_Projection")
            self.u_GradientInfo = glGetUniformLocation(program, "u_GradientInfo")
            self.u_TextureInfo  = glGetUniformLocation(program, "u_TextureInfo")
            self.a_Position     = glGetAttribLocation(program, "a_Position")
            self.a_RadialTexture = glGetAttribLocation(program, "a_RadialTexture")
            self.a_Texture      = glGetAttribLocation(program, "a_Texture")
            
            super.init(program: program)
            
            let atts = [self.a_Position, self.a_RadialTexture, self.a_Texture]
            print("Atts:\(atts)")
            self.addAttributes(atts)
        }
        
    }
    
    struct RadialVertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var radialTexture:(GLfloat, GLfloat) = (0.0, 0.0)
        var texture:(GLfloat, GLfloat)  = (0.0, 0.0)
    }
    
    public let gradient:GLGradientTexture2D
    let radialProgram = RadialGradientProgram()
    public let buffer:GLSFrameBuffer
    public var shadeTexture:CCTexture? = nil {
        didSet {
            self.shadeTextureChanged()
            self.bufferIsDirty = true
        }
    }
    
    let radialVertices = TexturedQuadVertices(vertex: RadialVertex())
    public var shouldRedraw = false
    public private(set) var bufferIsDirty = false
    
    public init(size:CGSize, gradient:GLGradientTexture2D) {
        
        self.buffer = GLSFrameBuffer(size: size)
        self.gradient = gradient
        
        self.radialVertices.iterateWithHandler() { index, vertex in
            let point = TexturedQuad.pointForIndex(index)
            let curPoint = point * size
            vertex.position = curPoint.getGLTuple()
            vertex.radialTexture = (point * 2.0 - 1.0).getGLTuple()
        }
        
        super.init(position: CGPoint.zero, size: size, texture: self.buffer.ccTexture)
        
        self.vertices = self.buffer.vertices
        
        self.shadeTextureChanged()
    }
    
    public func renderToTexture() {
        
        self.framebufferStack?.pushGLSFramebuffer(self.buffer)
        
        glUseProgram(self.radialProgram.program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.radialProgram.vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), self.radialVertices.size, self.radialVertices.vertices, GLenum(GL_STATIC_DRAW))
        
        //        let proj = GLSUniversalRenderer.sharedInstance.projection
        let proj = self.projection
        glUniformMatrix4fv(self.radialProgram.u_Projection, 1, 0, proj.values)
        
        self.pushTexture(self.gradient.textureName, atLocation: self.radialProgram.u_GradientInfo)
        self.pushTexture(self.shadeTexture?.name ?? 0, atLocation: self.radialProgram.u_TextureInfo)
        
        self.radialProgram.enableAttributes()
        self.radialProgram.bridgeAttributesWithSizes([2, 2, 2], stride: self.radialVertices.stride)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.radialVertices.count))
        
        self.radialProgram.disableAttributes()
        self.framebufferStack?.popFramebuffer()
        
        self.popTextures()
        self.bufferIsDirty = false
    }
    
    private func shadeTextureChanged() {
        
        let frame = self.shadeTexture?.frame ?? CGRect(square: 1.0)
        
        self.radialVertices.alterWithFrame(frame) { point, vertex in
            vertex.texture = point.getGLTuple()
            return
        }
    }
    
}
