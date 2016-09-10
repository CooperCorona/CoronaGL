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

public class GLSSprite: GLSNode {
   
//    var projection:SCMatrix4 = SCMatrix4()
    
    override public var texture:CCTexture? {
        didSet {
            self.setQuadForTexture()
        }
    }
    
    public var program:GLuint = 0
    public var vertexBuffer:GLuint = 0
    public var u_Projection:GLint = 0
    public var u_ModelMatrix:GLint = 0
    public var u_TextureInfo:GLint = 0
    public var u_Alpha:GLint = 0
    public var u_TintColor:GLint = 0
    public var u_TintIntensity:GLint = 0
    public var u_ShadeColor:GLint = 0
    public var a_Position:GLint = 0
    public var a_Texture:GLint = 0
    
    
    public var storedMatrix = SCMatrix4()
    
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
    
    override public func contentSizeChanged() {
        let sizeAsPoint = self.contentSize.getCGPoint()
        for iii in 0..<TexturedQuad.verticesPerQuad {
            vertices[iii].position = (TexturedQuad.pointForIndex(iii) * sizeAsPoint).getGLTuple()
        }
        self.verticesAreDirty = true
    }
    
    override public func loadProgram() {
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        
        program = ShaderHelper.programForString("Basic Shader")!
        
        u_Projection = glGetUniformLocation(program, "u_Projection")
        u_ModelMatrix = glGetUniformLocation(program, "u_ModelMatrix")
        u_TextureInfo = glGetUniformLocation(program, "u_TextureInfo")
        u_Alpha = glGetUniformLocation(program, "u_Alpha")
        u_TintColor = glGetUniformLocation(program, "u_TintColor")
        u_TintIntensity = glGetUniformLocation(program, "u_TintIntensity")
        u_ShadeColor = glGetUniformLocation(program, "u_ShadeColor")
        a_Position = glGetAttribLocation(program, "a_Position")
        a_Texture = glGetAttribLocation(program, "a_Texture")
    }//load program
    
    public func setQuadForTexture() {
        /*
        if let tex = texture {
            
            let minX = GLfloat(CGRectGetMinX(tex.frame))
            let maxX = GLfloat(CGRectGetMaxX(tex.frame))
            let minY = GLfloat(CGRectGetMinY(tex.frame))
            let maxY = GLfloat(CGRectGetMaxY(tex.frame))
            
            vertices[0].texture = (minX, maxY)
            vertices[1].texture = (minX, minY)
            vertices[2].texture = (maxX, maxY)
            vertices[3].texture = (maxX, minY)
            
        } else {
            for iii in 0..<4 {
                vertices[iii].texture = TexturedQuad.pointForIndex(iii).getGLTuple()
            }//loop through vertices
            
        }
        */
        
        let tFrame = self.texture?.frame ?? CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        TexturedQuad.setTexture(tFrame, ofVertices: &self.vertices)
        self.verticesAreDirty = true
    }//set quad for texture
    
    override public func render(model: SCMatrix4) {
        
        if (self.hidden) {
            return
        }//hidden: don't render
        
        
//        let childModel = self.modelMatrix() * model
        let childModel = modelMatrix() * model
        self.storedMatrix = childModel

        glUseProgram(program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), sizeof(UVertex) * self.vertices.count, self.vertices, GLenum(GL_STATIC_DRAW))
        

        glBindTexture(GLenum(GL_TEXTURE_2D), self.texture?.name ?? 0)
        glUniform1i(self.u_TextureInfo, 0)
        
        
        //        let proj = GLSUniversalRenderer.sharedInstance.projection
        let proj = self.projection
        glUniformMatrix4fv(self.u_Projection, 1, 0, proj.values)

        glUniformMatrix4fv(self.u_ModelMatrix, 1, 0, childModel.values)

        glUniform1f(self.u_Alpha, GLfloat(self.alpha))
        self.bridgeUniform3f(self.u_TintColor, vector: self.tintColor)
        self.bridgeUniform3f(self.u_TintIntensity, vector: self.tintIntensity)
        self.bridgeUniform3f(self.u_ShadeColor, vector: self.shadeColor)
        /*
        glUniform3f(self.u_TintColor, GLfloat(tintColor.r), GLfloat(tintColor.g), GLfloat(tintColor.b))
        glUniform3f(self.u_TintIntensity, GLfloat(tintIntensity.r), GLfloat(tintIntensity.g), GLfloat(tintIntensity.b))
        glUniform3f(self.u_ShadeColor, GLfloat(shadeColor.r), GLfloat(shadeColor.g), GLfloat(shadeColor.b))
        
        glEnableVertexAttribArray(GLuint(a_Position))
        glEnableVertexAttribArray(GLuint(a_Texture))
        
        let positionPointer = UnsafePointer<Void>(bitPattern: 0)
        glVertexAttribPointer(GLuint(a_Position), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(UVertex)), positionPointer)
        
        let texturePointer = UnsafePointer<Void>(bitPattern: sizeof(GLfloat) * 2)
        glVertexAttribPointer(GLuint(a_Texture), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(UVertex)), texturePointer)
        */
        let stride = sizeof(UVertex)
        self.bridgeAttribute(self.a_Position, size: 2, stride: stride, position: 0)
        self.bridgeAttribute(self.a_Texture, size: 2, stride: stride, position: 2)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.vertices.count))
        
        glDisableVertexAttribArray(GLuint(a_Position))
        glDisableVertexAttribArray(GLuint(a_Texture))
        
        super.render(model)
    }//render
    
    deinit {
        glDeleteBuffers(1, &self.vertexBuffer)
    }
    
    
    override public func clone() -> GLSSprite {
        
        let copiedSprite = GLSSprite(position: self.position, size: self.contentSize, texture: self.texture)
        
        copiedSprite.copyFromSprite(self)
        
        return copiedSprite
        
    }//clone
    
    public func copyFromSprite(node:GLSSprite) {
        
        super.copyFromNode(node)
        
        self.tintColor = node.tintColor
        self.tintIntensity = node.tintIntensity
        self.shadeColor = node.shadeColor
        
    }//copy from 'node'
    
}
