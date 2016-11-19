//
//  GLSCheckerSprite.swift
//  NoisyImagesOSX
//
//  Created by Cooper Knaak on 5/5/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

open class GLSCheckerSprite: GLSNode {

    open var offColor:SCVector4
    open var onColor:SCVector4
    open var checkerSize:CGFloat = 32.0 {
        didSet {
            self.checkerSizeChanged()
        }
    }
    
    open let program = ShaderHelper.programDictionaryForString("Checker Shader")!
    
    public init(off:SCVector4, on:SCVector4, size:CGSize) {
        self.offColor   = off
        self.onColor    = on
        super.init(position: CGPoint.zero, size: size)
        self.vertices = [UVertex](repeating: UVertex(), count: TexturedQuad.verticesPerQuad)
        self.contentSizeChanged()
    }
    
    open override func contentSizeChanged() {
        self.checkerSizeChanged()
    }
    
    open func checkerSizeChanged() {
        let quad = TexturedQuadVertices(vertices: self.vertices)
        quad.iterateWithHandler() { index, vertex in
            let p = TexturedQuad.pointForIndex(index)
            vertex.position = (p * self.contentSize).getGLTuple()
            vertex.texture = (p * self.contentSize / self.checkerSize).getGLTuple()
        }
        self.vertices = quad.vertices
    }
    
    open override func render(_ model: SCMatrix4) {
        if self.hidden {
            return
        }
        let childModel = self.modelMatrix()
        
        self.program.use()
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(self.vertices.count * MemoryLayout<UVertex>.size), self.vertices, GLenum(GL_STREAM_DRAW))
        
        self.program.uniformMatrix4fv("u_Projection", matrix: self.projection)
        self.program.uniformMatrix4fv("u_ModelMatrix", matrix: childModel)
        
        self.program.uniform4f("u_OffColor", value: self.offColor)
        self.program.uniform4f("u_OnColor", value: self.onColor)
        
        self.program.enableAttributes()
        self.program.bridgeAttributesWithSizes([2, 2], stride: MemoryLayout<UVertex>.size)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.vertices.count))
        
        self.program.disableAttributes()
        
        super.render(model)
    }
}
