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

public class StaticRenderer: NSObject {

    // MARK: - Types
    
    public class Program: GLProgramDictionary {
        
        public init() {
            
            guard let program = ShaderHelper.programForString("Universal 2D Shader") else {
                fatalError("Basic Shader does not exist!")
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
    
    public static let backgroundQueue       = dispatch_queue_create("Static Renderer Queue", DISPATCH_QUEUE_SERIAL)
    private let operationQueue              = NSOperationQueue()
    private let program                     = Program()
    private var vertices:[UVertex]          = []
    private var modelMatrices:[GLfloat]     = []
    private var shadeColors:[GLfloat]       = []
    private var tintColors:[GLfloat]        = []
    private var tintIntensities:[GLfloat]   = []
    private var alphas:[GLfloat]            = []
    private var count                       = 0
    private var currentTexture:GLuint       = 0
    
    private var allVertices:[[UVertex]]      = []
    private var allModelMatrices:[[GLfloat]] = []
    private var allShadeColors:[[GLfloat]]   = []
    private var allTintColors:[[GLfloat]]    = []
    private var allTintIntensities:[[GLfloat]] = []
    private var allAlphas:[[GLfloat]]        = []
    private var allTextures:[GLuint]         = []
    
    private var doubleBufferedSprites:[DoubleBuffered] = []
    
    public var asynchronous                 = false
    public var clearColor                   = SCVector4.blackColor
    private var onFirstRender               = true
    
    // MARK: - Setup
    
    override public init() {
        self.operationQueue.underlyingQueue = StaticRenderer.backgroundQueue
        super.init()
    }
    
    // MARK: - Logic
    public func renderNode(node:GLSNode) {
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
                dispatch_sync(dispatch_get_main_queue()) {
                    self.renderAll()
                }
            } else {
                self.renderAll()
            }
        }
        if self.asynchronous {
            dispatch_async(StaticRenderer.backgroundQueue, block)
        } else {
            block()
        }
    }
    
    private func iterateNode(node:GLSNode, matrix:SCMatrix4) {
        
        if let texture = node.texture where !node.hidden && node.vertices.count > 0 {
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
        
        if let dbSprite = node as? DoubleBuffered where dbSprite.bufferIsDirty {
            self.doubleBufferedSprites.append(dbSprite)
        }
        
        for child in node.children {
            self.iterateNode(child, matrix: node.modelMatrix(false) * matrix)
        }
    }
    
    private func addNode(node:GLSNode, matrix:SCMatrix4) {
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
    
    private func addBatch() -> Bool {
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
    
    private func renderAll() {
        
        guard self.allAlphas.count > 0 else {
            return
        }
        
        for sprite in self.doubleBufferedSprites {
            sprite.renderToTexture()
        }
        
        self.clearColor.bindGLClearColor()
        self.program.use()

        for i in self.allVertices.range {
            glBufferData(GLenum(GL_ARRAY_BUFFER), sizeof(UVertex) * self.allVertices[i].count, self.allVertices[i], GLenum(GL_STREAM_DRAW))
            glUniformMatrix4fv(self.program["u_Projection"], 1, 0, GLSNode.universalProjection.values)
            glUniformMatrix4fv(self.program["u_ModelMatrix"], GLsizei(self.allModelMatrices[i].count / 16), 0, self.allModelMatrices[i])
            glUniform3fv(self.program["u_ShadeColor"], GLsizei(self.allShadeColors[i].count / 3), self.allShadeColors[i])
            glUniform3fv(self.program["u_TintColor"], GLsizei(self.allTintColors[i].count / 3), self.allTintColors[i])
            glUniform3fv(self.program["u_TintIntensity"], GLsizei(self.allTintIntensities[i].count / 3), self.allTintIntensities[i])
            glUniform1fv(self.program["u_Alpha"], GLsizei(self.allAlphas[i].count), self.allAlphas[i])
            
            glBindTexture(GLenum(GL_TEXTURE_2D), self.allTextures[i])
            glUniform1i(self.program["u_TextureInfo"], 0)
            
            self.program.enableAttributes()
            self.program.bridgeAttributesWithSizes([2, 2, 1], stride: sizeof(UVertex))
            glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.allVertices[i].count))
            self.program.disableAttributes()
        }
    }
    
    private func renderCurrent() {
        self.addBatch()
        return
        
        if self.asynchronous {
            dispatch_sync(dispatch_get_main_queue()) {
                if self.onFirstRender {
                    self.onFirstRender = false
                    self.clearColor.bindGLClearColor()
                }
                let count = GLsizei(self.count)
                
                self.program.use()
                glBufferData(GLenum(GL_ARRAY_BUFFER), sizeof(UVertex) * self.vertices.count, self.vertices, GLenum(GL_STREAM_DRAW))
                glUniformMatrix4fv(self.program["u_Projection"], 1, 0, GLSNode.universalProjection.values)
                glUniformMatrix4fv(self.program["u_ModelMatrix"], count, 0, self.modelMatrices)
                glUniform3fv(self.program["u_ShadeColor"], count, self.shadeColors)
                glUniform3fv(self.program["u_TintColor"], count, self.tintColors)
                glUniform3fv(self.program["u_TintIntensity"], count, self.tintIntensities)
                glUniform1fv(self.program["u_Alpha"], count, self.alphas)
                
                glBindTexture(GLenum(GL_TEXTURE_2D), self.currentTexture)
                glUniform1i(self.program["u_TextureInfo"], 0)
                
                self.program.enableAttributes()
                self.program.bridgeAttributesWithSizes([2, 2, 1], stride: sizeof(UVertex))
                glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.vertices.count))
                self.program.disableAttributes()
//                self.done = true
            }
        } else {
            let count = GLsizei(self.count)
            
            self.program.use()
            glBufferData(GLenum(GL_ARRAY_BUFFER), sizeof(UVertex) * self.vertices.count, self.vertices, GLenum(GL_STREAM_DRAW))
            glUniformMatrix4fv(self.program["u_Projection"], 1, 0, GLSNode.universalProjection.values)
            glUniformMatrix4fv(self.program["u_ModelMatrix"], count, 0, self.modelMatrices)
            glUniform3fv(self.program["u_ShadeColor"], count, self.shadeColors)
            glUniform3fv(self.program["u_TintColor"], count, self.tintColors)
            glUniform3fv(self.program["u_TintIntensity"], count, self.tintIntensities)
            glUniform1fv(self.program["u_Alpha"], count, self.alphas)
            
            glBindTexture(GLenum(GL_TEXTURE_2D), self.currentTexture)
            glUniform1i(self.program["u_TextureInfo"], 0)
            
            self.program.enableAttributes()
            self.program.bridgeAttributesWithSizes([2, 2, 1], stride: sizeof(UVertex))
            glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.vertices.count))
            self.program.disableAttributes()
        }
    }
    
    private func resetArrays() {
        self.count              = 0
        self.vertices           = []
        self.modelMatrices      = []
        self.shadeColors        = []
        self.tintColors         = []
        self.tintIntensities    = []
        self.alphas             = []
    }
    
    public func performBlock(block:() -> Void) {
        if self.asynchronous {
            dispatch_async(StaticRenderer.backgroundQueue, block)
        } else {
            block()
        }
    }
}
