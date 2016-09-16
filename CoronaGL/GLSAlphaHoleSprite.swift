//
//  GLSAlphaHoleSprite.swift
//  Batcher
//
//  Created by Cooper Knaak on 11/21/15.
//  Copyright © 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures
/**
Renders to a background texture with a configurable circular alpha attenuation.
*/
open class GLSAlphaHoleSprite: GLSSprite, DoubleBuffered {

    // MARK: - Properties
    
    fileprivate let alphaProgram            = ShaderHelper.programDictionaryForString("Alpha Hole Shader")!
    ///The position at which the attenuation is centered.
    open var fadePosition:CGPoint     = CGPoint.zero {
        didSet {
            if self.inAnimationBlock {
                self.add2Animation(oldValue, end: self.fadePosition) { [unowned self] in self.fadePosition = $0 }
                self.fadePosition = oldValue
            }
            
            self.bufferIsDirty = true
        }
    }
    ///The inner radius of the attenuation. Any distance <= innerRadius uses the innerAlpha.
    open var innerRadius:CGFloat      = 0.0 {
        didSet {
            if self.inAnimationBlock {
                self.add1Animation(oldValue, end: self.innerRadius) { [unowned self] in self.innerRadius = $0 }
                self.innerRadius = oldValue
            }
            
            self.bufferIsDirty = true
        }
    }
    ///The outer radius of the attenuation. Any distance >= outerRadius uses the outerAlpha.
    open var outerRadius:CGFloat      = 0.0 {
        didSet {
            if self.inAnimationBlock {
                self.add1Animation(oldValue, end: self.outerRadius) { [unowned self] in self.outerRadius = $0 }
                self.outerRadius = oldValue
            }
            
            self.bufferIsDirty = true
        }
    }
    ///The alpha of the inner portion of the hole.
    open var innerAlpha:CGFloat       = 0.0 {
        didSet {
            if self.inAnimationBlock {
                self.add1Animation(oldValue, end: self.innerAlpha) { [unowned self] in self.innerAlpha = $0 }
                self.innerAlpha = oldValue
            }
            
            self.bufferIsDirty = true
        }
    }
    ///The alpha of the outer portion of the whole.
    open var outerAlpha:CGFloat       = 0.0 {
        didSet {
            if self.inAnimationBlock {
                self.add1Animation(oldValue, end: self.outerAlpha) { [unowned self] in self.outerAlpha = $0 }
                self.outerAlpha = oldValue
            }
            
            self.bufferIsDirty = true
        }
    }
    ///The texture to render.
    open var alphaTexture:CCTexture?  = nil {
        didSet {
            if let tFrame = self.alphaTexture?.frame {
                self.alphaVertices.alterWithFrame(tFrame) { (point:CGPoint, vertex:inout UVertex) in
                    vertex.texture = point.getGLTuple()
                }
            }
            self.bufferIsDirty = true
        }
    }
    ///Whether or not to render the attenuation.
    open var active                   = true
    open var shouldRedraw             = false
    open fileprivate(set) var bufferIsDirty = false
    
    fileprivate let alphaVertices = TexturedQuadVertices(vertex: UVertex())
    ///The offscreen buffer the texture is rendered to.
    open let buffer:GLSFrameBuffer
    
    // MARK: - Setup
    
    ///Initialize with a given size and texture.
    public init(size:CGSize, texture:CCTexture?) {
        
        self.alphaTexture = texture
        self.buffer = GLSFrameBuffer(size: size)
        self.alphaVertices.iterateWithHandler() { index, vertex in
            let point = TexturedQuad.pointForIndex(index)
            vertex.position = (point * size).getGLTuple()
            vertex.texture = point.getGLTuple()
        }
        
        super.init(position: CGPoint.zero, size: size, texture: self.buffer.ccTexture)
        
        if let tFrame = texture?.frame {
            self.alphaVertices.alterWithFrame(tFrame) { (point:CGPoint, vertex:inout UVertex) in
                vertex.texture = point.getGLTuple()
            }
        }
    }
    
    // MARK: - Logic
    
    ///Invoked when the content size is changed. Updates the vertices for the new size.
    open override func contentSizeChanged() {
        self.alphaVertices.iterateWithHandler() { [unowned self] index, vertex in
            let point = TexturedQuad.pointForIndex(index)
            vertex.position = (point * self.contentSize).getGLTuple()
        }
    }
    
    ///Renders to the background buffer.
    open func renderToTexture() {
        self.framebufferStack?.pushGLSFramebuffer(buffer: self.buffer)
        SCVector4().bindGLClearColor()
        
        self.alphaProgram.use()
        self.alphaVertices.bufferDataWithVertexBuffer(self.alphaProgram.vertexBuffer)
        
//        let model = self.modelMatrix()
        let model = SCMatrix4()

        self.alphaProgram.uniformMatrix4fv("u_Projection", matrix: self.projection)
        self.alphaProgram.uniformMatrix4fv("u_ModelMatrix", matrix: model)
        self.alphaProgram.uniform2f("u_FadePosition", value: self.fadePosition)
        self.alphaProgram.uniform1f("u_InnerRadius", value: self.innerRadius)
        self.alphaProgram.uniform1f("u_OuterRadius", value: self.outerRadius)
        self.alphaProgram.uniform1f("u_InnerAlpha", value: self.innerAlpha)
        self.alphaProgram.uniform1f("u_OuterAlpha", value: self.outerAlpha)
        print("Inner Alpha: \(self.innerAlpha)")
//        glUniformMatrix4fv(self.alphaProgram["u_Projection"], 1, 0, proj.values)
//        glUniformMatrix4fv(self.alphaProgram["u_ModelMatrix"], 1, 0, model.values)
//        self.alphaProgram.uniform2f("u_FadePosition", value: self.fadePosition)
        
//        glUniform1f(self.alphaProgram["u_InnerRadius"], GLfloat(self.innerRadius))
//        glUniform1f(self.alphaProgram["u_OuterRadius"], GLfloat(self.outerRadius))
//        glUniform1f(self.alphaProgram["u_InnerAlpha"], self.active ? GLfloat(self.innerAlpha) : 1.0)
//        glUniform1f(self.alphaProgram["u_OuterAlpha"], self.active ? GLfloat(self.outerAlpha) : 1.0)
        
        glBindTexture(GLenum(GL_TEXTURE_2D), self.alphaTexture?.name ?? 0)
        glUniform1i(self.alphaProgram["u_TextureInfo"], 0)
        
        self.alphaProgram.enableAttributes()
        self.alphaProgram.bridgeAttributesWithSizes([2, 2], stride: MemoryLayout<UVertex>.size)
        
        self.alphaVertices.drawArrays()
        self.alphaProgram.disable()
        
        self.framebufferStack?.popFramebuffer()
        self.bufferIsDirty = false
    }
    
}
