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

open class GLSRadialGradientSprite: GLSSprite, DoubleBuffered {

    struct RadialVertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var radialTexture:(GLfloat, GLfloat) = (0.0, 0.0)
        var texture:(GLfloat, GLfloat)  = (0.0, 0.0)
    }
    
    open let gradient:GLGradientTexture2D
    let radialProgram = ShaderHelper.programDictionaryForString("Radial Gradient Shader")!
    open let buffer:GLSFrameBuffer
    open var shadeTexture:CCTexture? = nil {
        didSet {
            self.shadeTextureChanged()
            self.bufferIsDirty = true
        }
    }
    
    let radialVertices = TexturedQuadVertices(vertex: RadialVertex())
    open var shouldRedraw = false
    open fileprivate(set) var bufferIsDirty = false
    
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
    
    open func renderToTexture() {
        
        self.framebufferStack?.pushGLSFramebuffer(buffer: self.buffer)
        
        self.radialProgram.use()
        glBufferData(GLenum(GL_ARRAY_BUFFER), self.radialVertices.size, self.radialVertices.vertices, GLenum(GL_STATIC_DRAW))
        
        self.radialProgram.uniformMatrix4fv("u_Projection", matrix: self.projection)
        
        self.pushTexture(self.gradient.textureName, atLocation: self.radialProgram["u_GradientInfo"])
        self.pushTexture(self.shadeTexture?.name ?? 0, atLocation: self.radialProgram["u_TextureInfo"])
        
        self.radialProgram.enableAttributes()
        self.radialProgram.bridgeAttributesWithSizes([2, 2, 2], stride: self.radialVertices.stride)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.radialVertices.count))
        
        self.radialProgram.disable()
        self.framebufferStack?.popFramebuffer()
        
        self.popTextures()
        self.bufferIsDirty = false
    }
    
    fileprivate func shadeTextureChanged() {
        
        let frame = self.shadeTexture?.frame ?? CGRect(square: 1.0)
        
        self.radialVertices.alterWithFrame(frame) { point, vertex in
            vertex.texture = point.getGLTuple()
            return
        }
    }
    
}
