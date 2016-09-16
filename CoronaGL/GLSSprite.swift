//
//  GLSSprite.swift
//  Fields and Forces
//
//  Created by Cooper Knaak on 12/13/14.
//  Copyright (c) 2014 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

open class GLSSprite: GLSNode {
   
//    var projection:SCMatrix4 = SCMatrix4()
    
    override open var texture:CCTexture? {
        didSet {
            self.setQuadForTexture()
        }
    }
    
    open let program = ShaderHelper.programDictionaryForString("Basic Shader")!
    
    open var storedMatrix = SCMatrix4()
    
    public init(position:CGPoint, size:CGSize, texture:CCTexture?) {
        
        super.init(position:position, size:size)
        
        let sizeAsPoint = size.getCGPoint()
        for iii in 0..<TexturedQuad.verticesPerQuad {
            self.vertices.append(UVertex())
            
            let pnt = TexturedQuad.pointForIndex(iii)
            vertices[iii].texture = pnt.getGLTuple()
            vertices[iii].position = (pnt * sizeAsPoint).getGLTuple()
        }
        
        self.texture = texture
        self.setQuadForTexture()
    }//initialize
    
    public convenience init(size:CGSize, texture:CCTexture?) {
        self.init(position: CGPoint.zero, size: size, texture: texture)
    }//initialize (without specifiying position)
    
    public convenience init(texture:CCTexture?) {
        self.init(size: CGSize.zero, texture: texture)
    }//initialize (only using texture)
    
    override open func contentSizeChanged() {
        let sizeAsPoint = self.contentSize.getCGPoint()
        for iii in 0..<TexturedQuad.verticesPerQuad {
            vertices[iii].position = (TexturedQuad.pointForIndex(iii) * sizeAsPoint).getGLTuple()
        }
        self.verticesAreDirty = true
    }
    
    open func setQuadForTexture() {
        let tFrame = self.texture?.frame ?? CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        TexturedQuad.setTexture(tFrame, ofVertices: &self.vertices)
        self.verticesAreDirty = true
    }//set quad for texture
    
    override open func render(_ model: SCMatrix4) {
        
        if (self.hidden) {
            return
        }//hidden: don't render
        
        let childModel = modelMatrix() * model
        self.storedMatrix = childModel

        self.program.use()
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<UVertex>.size * self.vertices.count, self.vertices, GLenum(GL_STATIC_DRAW))
        
        glBindTexture(GLenum(GL_TEXTURE_2D), self.texture?.name ?? 0)
        glUniform1i(self.program["u_TextureInfo"], 0)
        
        self.program.uniformMatrix4fv("u_Projection", matrix: self.projection)
        self.program.uniformMatrix4fv("u_ModelMatrix", matrix: childModel)

        glUniform1f(self.program["u_Alpha"], GLfloat(self.alpha))
        self.bridgeUniform3f(self.program["u_TintColor"], vector: self.tintColor)
        self.bridgeUniform3f(self.program["u_TintIntensity"], vector: self.tintIntensity)
        self.bridgeUniform3f(self.program["u_ShadeColor"], vector: self.shadeColor)

        self.program.enableAttributes()
        self.program.bridgeAttributesWithSizes([2, 2, 1], stride: MemoryLayout<UVertex>.size)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.vertices.count))
        
        self.program.disable()
        
        super.render(model)
    }//render
    
    override open func clone() -> GLSSprite {
        
        let copiedSprite = GLSSprite(position: self.position, size: self.contentSize, texture: self.texture)
        
        copiedSprite.copyFromSprite(self)
        
        return copiedSprite
        
    }//clone
    
    open func copyFromSprite(_ node:GLSSprite) {
        
        super.copyFromNode(node)
        
        self.tintColor = node.tintColor
        self.tintIntensity = node.tintIntensity
        self.shadeColor = node.shadeColor
        
    }//copy from 'node'
    
}
