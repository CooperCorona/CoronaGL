//
//  GLSGradientSprite.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 6/8/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

///Maps a gradient to a texture
public class GLSGradientSprite: GLSSprite, DoubleBuffered {
   
    // MARK: - Types
    class GradientProgram: GLAttributeBridger {
        let u_Projection:GLint
        let u_TextureInfo:GLint
        let u_GradientInfo:GLint
        let a_Position:GLint
        let a_Texture:GLint
        
        init(type:GradientType) {
//            let program = ShaderHelper.programForString("Basic Gradient Shader")!
            let program:GLuint
            switch type {
            case .Mapped:
                program = ShaderHelper.programForString("Basic Gradient Shader")!
            case .Radial:
                program = ShaderHelper.programForString("Radial Gradient Shader")!
            }
            
            self.u_Projection   = glGetUniformLocation(program, "u_Projection")
            self.u_TextureInfo  = glGetUniformLocation(program, "u_TextureInfo")
            self.u_GradientInfo = glGetUniformLocation(program, "u_GradientInfo")
            self.a_Position     = glGetAttribLocation(program, "a_Position")
            self.a_Texture      = glGetAttribLocation(program, "a_Texture")
            
            super.init(program: program)
            
            let atts = [self.a_Position, self.a_Texture]
            self.addAttributes(atts)
        }
        
    }
    
    ///The ways a *GLSGradientSprite* can render a gradient.
    enum GradientType: String {
        case Mapped = "Mapped"
        case Radial = "Radial"
    }
    
    struct GradientVertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var texture:(GLfloat, GLfloat)  = (0.0, 0.0)
    }
    
    // MARK: - Properties
    
    private(set) var gradientProgram = GradientProgram(type: .Mapped)
    
    /**
    How the sprite renders the gradient.
    
    If *.Mapped*, then *mapTexture* is used as a color map.
    
    If *.Radial*, then *mapTexture* is used as a mask and the
    gradient is rendered radially (counterclockwise, starting at angle 0.0).
    */
    var gradientType:GradientType = .Mapped {
        didSet {
            if self.gradientType != oldValue {
                self.gradientProgram = GradientProgram(type: self.gradientType)
                self.bufferIsDirty = true
            }
        }
    }
    
    ///Uses the R value to map colors to the gradient.
    public var mapTexture:CCTexture? = nil {
        didSet {
            self.mapTextureChanged()
            self.bufferIsDirty = true
        }
    }
    
    ///The gradient of colors to use.
    public var gradient:GLGradientTexture2D {
        didSet {
            self.bufferIsDirty = true
        }
    }
    
    ///The background buffer that the sprite is drawn to.
    public let buffer:GLSFrameBuffer
    public var shouldRedraw = false
    public private(set) var bufferIsDirty = false
    
    ///The vertices used to draw the sprite.
    let gradientVertices = TexturedQuadVertices(vertex: GradientVertex())
    
    // MARK: - Setup
    
    /**
    Initialize a GLSGradientSprite with a gradient and map texture.
    
    - parameter size: The size of the sprite.
    - parameter texture: The texture that determines the mapping.
    - parameter gradient: The gradient of colors that is mapped.
    - returns: The initializd GLSGradientSprite object.
    */
    public init(size:CGSize, texture:CCTexture?, gradient:GLGradientTexture2D) {
        
        self.buffer     = GLSFrameBuffer(size: size)
        self.mapTexture = texture
        self.gradient   = gradient
        
        self.gradientVertices.iterateWithHandler() { index, vertex in
            let point = TexturedQuad.pointForIndex(index) * size
            vertex.position = point.getGLTuple()
        }
        
        super.init(position: CGPoint.zero, size: size, texture: self.buffer.ccTexture)
        
        self.mapTextureChanged()
    }
    
    /**
    Renders the gradient sprite to the background buffer.

    - returns: *true* if the sprite was rendered, *false* if the framebuffer could not be pushed.
    */
    public func renderToTexture() {
        
        if let didPush = self.framebufferStack?.pushGLSFramebuffer(self.buffer) {
            if !didPush {
                print("Error! Could not push framebuffer!")
                return
            }
        } else {
            print("Error! Framebuffer stack is nil!")
            return
        }
        
        glUseProgram(self.gradientProgram.program)
        self.gradientVertices.bufferDataWithVertexBuffer(self.gradientProgram.vertexBuffer)
        
        //        let proj = GLSUniversalRenderer.sharedInstance.projection
        let proj = self.projection
        glUniformMatrix4fv(self.gradientProgram.u_Projection, 1, 0, proj.values)
        
        self.pushTexture(self.mapTexture?.name ?? 0, atLocation: self.gradientProgram.u_TextureInfo)
        self.pushTexture(self.gradient.textureName, atLocation: self.gradientProgram.u_GradientInfo)
       
        self.gradientProgram.enableAttributes()
        self.gradientProgram.bridgeAttributesWithSizes([2, 2], stride: self.gradientVertices.stride)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.gradientVertices.count))
        
        self.gradientProgram.disableAttributes()
        self.popTextures()
        self.framebufferStack?.popFramebuffer()
        
        self.bufferIsDirty = false
    }
    
    private func mapTextureChanged() {
        let frame = self.mapTexture?.frame ?? CGRect(square: 1.0)
        self.gradientVertices.alterWithFrame(frame) { point, vertex in
            let tuple = point.getGLTuple()
            vertex.texture = tuple
        }
    }
    
}
