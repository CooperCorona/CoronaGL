//
//  StaticRenderer.swift
//  Batcher
//
//  Created by Cooper Knaak on 11/30/15.
//  Copyright © 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

open class StaticRenderer: NSObject {

    // MARK: - Types
    
    open class Program: GLProgramDictionary {
        
        public init() {
            
            guard let program = ShaderHelper.programForString("Universal2 D Shader") else {
                fatalError("Universal 2D Shader does not exist!")
            }
            
            super.init(program: program, locations: [
                "u_Projection",
                "u_ModelMatrix",
                "u_ShadeColor",
                "u_TintColor",
                "u_TintIntensity",
                "u_TextureInfo",
                "u_Alpha",
                "a_Position",
                "a_Texture",
                "a_Index"
            ])
            
            glUseProgram(program)
        }
        
    }
    
    // MARK: - Properties
    
    open static let backgroundQueue       = DispatchQueue(label: "Static Renderer Queue", attributes: [])
    fileprivate let operationQueue              = OperationQueue()
    fileprivate let program                     = Program()
    fileprivate var vertices:[UVertex]          = []
    fileprivate var modelMatrices:[GLfloat]     = []
    fileprivate var shadeColors:[GLfloat]       = []
    fileprivate var tintColors:[GLfloat]        = []
    fileprivate var tintIntensities:[GLfloat]   = []
    fileprivate var alphas:[GLfloat]            = []
    fileprivate var count                       = 0
    fileprivate var currentTexture:GLuint       = 0
    
    fileprivate var allVertices:[[UVertex]]      = []
    fileprivate var allModelMatrices:[[GLfloat]] = []
    fileprivate var allShadeColors:[[GLfloat]]   = []
    fileprivate var allTintColors:[[GLfloat]]    = []
    fileprivate var allTintIntensities:[[GLfloat]] = []
    fileprivate var allAlphas:[[GLfloat]]        = []
    fileprivate var allTextures:[GLuint]         = []
    
    fileprivate var doubleBufferedSprites:[DoubleBuffered] = []
    
    open var asynchronous                 = false
    open var clearColor                   = SCVector4.blackColor
    fileprivate var onFirstRender               = true
    
    // MARK: - Setup
    
    override public init() {
        self.operationQueue.underlyingQueue = StaticRenderer.backgroundQueue
        super.init()
    }
    
    // MARK: - Logic
    
    open func renderNode(_ node:GLSNode) {
        let block = {
            self.allVertices            = []
            self.allModelMatrices       = []
            self.allShadeColors         = []
            self.allTintColors          = []
            self.allTintIntensities     = []
            self.allAlphas              = []
            self.allTextures            = []
            self.doubleBufferedSprites  = []
            self.onFirstRender          = true
            
            self.resetArrays()
            self.iterateNode(node, matrix: SCMatrix4())
            self.addBatch()
            if self.asynchronous {
                DispatchQueue.main.sync {
                    self.renderAll()
                }
            } else {
                self.renderAll()
            }
        }
        if self.asynchronous {
            StaticRenderer.backgroundQueue.async(execute: block)
        } else {
            block()
        }
    }
    
    fileprivate func iterateNode(_ node:GLSNode, matrix:SCMatrix4) {
        
        if let texture = node.texture , !node.hidden && node.vertices.count > 0 {
            let childModel = node.modelMatrix() * matrix
            
            if self.count <= 0 {
                self.addNode(node, matrix: childModel)
                self.currentTexture = texture.name
            } else if texture.name == self.currentTexture {
                self.addNode(node, matrix: childModel)
            } else {
                self.addBatch()
                self.resetArrays()
                self.addNode(node, matrix: childModel)
                self.currentTexture = texture.name
            }
        }
        
        if let dbSprite = node as? DoubleBuffered , dbSprite.bufferIsDirty {
            self.doubleBufferedSprites.append(dbSprite)
        }
        
        for child in node.children {
            self.iterateNode(child, matrix: node.modelMatrix(false) * matrix)
        }
    }
    
    fileprivate func addNode(_ node:GLSNode, matrix:SCMatrix4) {
        let copiedVertices = node.vertices
        self.vertices           += copiedVertices.map() {
            var vertex = $0
            vertex.index = GLfloat(self.count)
            return vertex
        }
        self.modelMatrices      += matrix.values
        self.shadeColors        += node.shadeColor.getGLComponents()
        self.tintColors         += node.tintColor.getGLComponents()
        self.tintIntensities    += node.tintIntensity.getGLComponents()
        self.alphas.append(GLfloat(node.alpha))
        self.count += 1
    }
    
    fileprivate func addBatch() -> Bool {
        guard self.count > 0 else {
            return false
        }
        
        self.allVertices.append(self.vertices)
        self.allModelMatrices.append(self.modelMatrices)
        self.allShadeColors.append(self.shadeColors)
        self.allTintColors.append(self.tintColors)
        self.allTintIntensities.append(self.tintIntensities)
        self.allAlphas.append(self.alphas)
        self.allTextures.append(self.currentTexture)
        
        return true
    }
    
    fileprivate func renderAll() {
        
        guard self.allAlphas.count > 0 else {
            return
        }
        
        for sprite in self.doubleBufferedSprites {
            sprite.renderToTexture()
        }
        
        self.clearColor.bindGLClearColor()
        self.program.use()

        for i in self.allVertices.range {
            glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<UVertex>.size * self.allVertices[i].count, self.allVertices[i], GLenum(GL_STREAM_DRAW))
            glUniformMatrix4fv(self.program["u_Projection"], 1, 0, GLSNode.universalProjection.values)
            glUniformMatrix4fv(self.program["u_ModelMatrix"], GLsizei(self.allModelMatrices[i].count / 16), 0, self.allModelMatrices[i])
            glUniform3fv(self.program["u_ShadeColor"], GLsizei(self.allShadeColors[i].count / 3), self.allShadeColors[i])
            glUniform3fv(self.program["u_TintColor"], GLsizei(self.allTintColors[i].count / 3), self.allTintColors[i])
            glUniform3fv(self.program["u_TintIntensity"], GLsizei(self.allTintIntensities[i].count / 3), self.allTintIntensities[i])
            glUniform1fv(self.program["u_Alpha"], GLsizei(self.allAlphas[i].count), self.allAlphas[i])
            
            glBindTexture(GLenum(GL_TEXTURE_2D), self.allTextures[i])
            glUniform1i(self.program["u_TextureInfo"], 0)
            
            self.program.enableAttributes()
            self.program.bridgeAttributesWithSizes([2, 2, 1], stride: MemoryLayout<UVertex>.size)
            glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.allVertices[i].count))
            self.program.disableAttributes()
        }
    }
    
    fileprivate func renderCurrent() {
        self.addBatch()
        return
        
        if self.asynchronous {
            DispatchQueue.main.sync {
                if self.onFirstRender {
                    self.onFirstRender = false
                    self.clearColor.bindGLClearColor()
                }
                let count = GLsizei(self.count)
                
                self.program.use()
                glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<UVertex>.size * self.vertices.count, self.vertices, GLenum(GL_STREAM_DRAW))
                glUniformMatrix4fv(self.program["u_Projection"], 1, 0, GLSNode.universalProjection.values)
                glUniformMatrix4fv(self.program["u_ModelMatrix"], count, 0, self.modelMatrices)
                glUniform3fv(self.program["u_ShadeColor"], count, self.shadeColors)
                glUniform3fv(self.program["u_TintColor"], count, self.tintColors)
                glUniform3fv(self.program["u_TintIntensity"], count, self.tintIntensities)
                glUniform1fv(self.program["u_Alpha"], count, self.alphas)
                
                glBindTexture(GLenum(GL_TEXTURE_2D), self.currentTexture)
                glUniform1i(self.program["u_TextureInfo"], 0)
                
                self.program.enableAttributes()
                self.program.bridgeAttributesWithSizes([2, 2, 1], stride: MemoryLayout<UVertex>.size)
                glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.vertices.count))
                self.program.disableAttributes()
//                self.done = true
            }
        } else {
            let count = GLsizei(self.count)
            
            self.program.use()
            glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<UVertex>.size * self.vertices.count, self.vertices, GLenum(GL_STREAM_DRAW))
            glUniformMatrix4fv(self.program["u_Projection"], 1, 0, GLSNode.universalProjection.values)
            glUniformMatrix4fv(self.program["u_ModelMatrix"], count, 0, self.modelMatrices)
            glUniform3fv(self.program["u_ShadeColor"], count, self.shadeColors)
            glUniform3fv(self.program["u_TintColor"], count, self.tintColors)
            glUniform3fv(self.program["u_TintIntensity"], count, self.tintIntensities)
            glUniform1fv(self.program["u_Alpha"], count, self.alphas)
            
            glBindTexture(GLenum(GL_TEXTURE_2D), self.currentTexture)
            glUniform1i(self.program["u_TextureInfo"], 0)
            
            self.program.enableAttributes()
            self.program.bridgeAttributesWithSizes([2, 2, 1], stride: MemoryLayout<UVertex>.size)
            glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.vertices.count))
            self.program.disableAttributes()
        }
    }
    
    fileprivate func resetArrays() {
        self.count              = 0
        self.vertices           = []
        self.modelMatrices      = []
        self.shadeColors        = []
        self.tintColors         = []
        self.tintIntensities    = []
        self.alphas             = []
    }
    
    open func performBlock(_ block:@escaping () -> Void) {
        if self.asynchronous {
            StaticRenderer.backgroundQueue.async(execute: block)
        } else {
            block()
        }
    }
}
