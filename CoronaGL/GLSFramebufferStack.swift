//
//  GLSFramebufferStack.swift
//  Fields and Forces
//
//  Created by Cooper Knaak on 1/9/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

import GLKit
import CoronaStructures

#if os(iOS)
public class GLSFramebufferStack: NSObject {
   
    private let initialBuffer:GLKView
    private var buffers:[GLuint] = []
    fileprivate var viewports:[[GLint]] = []
    
    public init(initialBuffer:GLKView) {
        
        self.initialBuffer = initialBuffer
        
        super.init()
    }//initialize
    
    private func getViewport() -> [GLint] {
        var viewport:[GLint] = [-1, -1, -1, -1]
        glGetIntegerv(GLenum(GL_VIEWPORT), &viewport)
        return viewport
    }
    
    public func pushFramebuffer(buffer:GLuint) -> Bool {
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), buffer)
        self.buffers.append(buffer)
        
        //We can't infer anything about the framebuffer's
        //size (well, there might be a glGet option, but
        //I don't know for sure), so we just duplicate
        //the current state.
        self.viewports.append(self.getViewport())
        
        return true
    }//push a framebuffer
    
    public func pushGLSFramebuffer(buffer:GLSFrameBuffer) -> Bool {
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), buffer.framebuffer)
        self.buffers.append(buffer.framebuffer)
        
        let viewport = [0, 0, GLint(buffer.size.width), GLint(buffer.size.height)]
        glViewport(GLsizei(viewport[0]), GLsizei(viewport[1]), GLsizei(viewport[2]), GLsizei(viewport[3]))
        viewports.append(viewport)
        return true
    }//push a framebuffer
    
    public func popFramebuffer() -> Bool {
        
        if (buffers.count <= 0) {
            return false
        }//can't pop initial framebuffer
        
        self.buffers.removeLast()
        
        if let topBuffer = self.buffers.last, let viewport = self.viewports.last {
            glBindFramebuffer(GLenum(topBuffer), topBuffer)
            glViewport(GLsizei(viewport[0]), GLsizei(viewport[1]), GLsizei(viewport[2]), GLsizei(viewport[3]))
        } else {
            self.initialBuffer.bindDrawable()
        }
        
        return true
    }//pop the top framebuffer
    
}
    
#else
    
open class GLSFramebufferStack: NSObject {
    
    fileprivate let initialBuffer:NSOpenGLView?
    fileprivate var buffers:[GLuint] = []
    fileprivate var renderBuffers:[GLuint] = []
    fileprivate var viewports:[[GLint]] = []
    fileprivate var projections:[SCMatrix4] = []
    open let internalContext:NSOpenGLContext?
    
    public init(initialBuffer:NSOpenGLView?) {
        self.initialBuffer = initialBuffer
        self.internalContext = GLSFrameBuffer.globalContext
        super.init()
    }//initialize
    
    private func getViewport() -> [GLint] {
        var viewport:[GLint] = [-1, -1, -1, -1]
        glGetIntegerv(GLenum(GL_VIEWPORT), &viewport)
        return viewport
    }
    
    private func set(viewport:[GLint]) {
        glViewport(GLsizei(viewport[0]), GLsizei(viewport[1]), GLsizei(viewport[2]), GLsizei(viewport[3]))
    }
    
    open func pushFramebuffer(buffer:GLuint) -> Bool {
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), buffer)
        self.buffers.append(buffer)
        
        //We can't infer anything about the framebuffer's
        //size (well, there might be a glGet option, but
        //I don't know for sure), so we just duplicate
        //the current state.
        self.viewports.append(self.getViewport())
        
        return true
    }//push a framebuffer
    
    @discardableResult open func pushGLSFramebuffer(buffer:GLSFrameBuffer) -> Bool {
        self.internalContext?.makeCurrentContext()

        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), buffer.framebuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), buffer.renderBuffer)
        //TODO: Figure out if this needs to be internalSize or not.
        let viewport = [0, 0, GLint(buffer.size.width), GLint(buffer.size.height)]
        self.set(viewport: viewport)
        
        self.projections.append(GLSNode.universalProjection)
        GLSNode.universalProjection = SCMatrix4(right: CGFloat(viewport[2]), top: CGFloat(viewport[3]))
        
        self.buffers.append(buffer.framebuffer)
        self.renderBuffers.append(buffer.renderBuffer)
        self.viewports.append(viewport)
        
        return true
    }//push a framebuffer
    
    @discardableResult open func popFramebuffer() -> Bool {
        
        if (self.buffers.count <= 0) {
            return false
        }//can't pop initial framebuffer
        
        //renderBuffers is guarunteed to be the same length as buffers.
        self.buffers.removeLast()
        self.renderBuffers.removeLast()
        self.viewports.removeLast()
        GLSNode.universalProjection = self.projections.removeLast()
        
        if let topBuffer = self.buffers.last, let renderBuffer = self.renderBuffers.last, let viewport = self.viewports.last {
            glBindFramebuffer(GLenum(topBuffer), topBuffer)
            glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
            glViewport(GLsizei(viewport[0]), GLsizei(viewport[1]), GLsizei(viewport[2]), GLsizei(viewport[3]))
        } else {
            glFlush()
            self.initialBuffer?.openGLContext?.makeCurrentContext()
        }
        
        return true
    }//pop the top framebuffer
    
}
#endif
