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
    
    public init(initialBuffer:GLKView) {
        
        self.initialBuffer = initialBuffer
        
        super.init()
    }//initialize
    
    public func pushFramebuffer(buffer:GLuint) -> Bool {
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), buffer)
        self.buffers.append(buffer)
        
        return true
    }//push a framebuffer
    
    public func pushGLSFramebuffer(buffer:GLSFrameBuffer) -> Bool {
        
        return self.pushFramebuffer(buffer: buffer.framebuffer)
        
    }//push a framebuffer
    
    public func popFramebuffer() -> Bool {
        
        if (buffers.count <= 0) {
            return false
        }//can't pop initial framebuffer
        
        self.buffers.removeLast()
        
        if let topBuffer = self.buffers.last {
            glBindFramebuffer(GLenum(topBuffer), topBuffer)
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
    open let internalContext:NSOpenGLContext?
    
    public init(initialBuffer:NSOpenGLView?) {
        self.initialBuffer = initialBuffer
        self.internalContext = GLSFrameBuffer.globalContext
        super.init()
    }//initialize
    
    
    open func pushFramebuffer(buffer:GLuint) -> Bool {
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), buffer)
        self.buffers.append(buffer)
        
        return true
    }//push a framebuffer
    
    open func pushGLSFramebuffer(buffer:GLSFrameBuffer) -> Bool {
        self.internalContext?.makeCurrentContext()

        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), buffer.framebuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), buffer.renderBuffer)
        
        self.buffers.append(buffer.framebuffer)
        self.renderBuffers.append(buffer.renderBuffer)
        
        return true
    }//push a framebuffer
    
    open func popFramebuffer() -> Bool {
        
        if (self.buffers.count <= 0) {
            return false
        }//can't pop initial framebuffer
        
        //renderBuffers is guarunteed to be the same length as buffers.
        self.buffers.removeLast()
        self.renderBuffers.removeLast()
        
        if let topBuffer = self.buffers.last, let renderBuffer = self.renderBuffers.last {
            glBindFramebuffer(GLenum(topBuffer), topBuffer)
            glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        } else {
            glFlush()
            self.initialBuffer?.openGLContext?.makeCurrentContext()
        }
        
        return true
    }//pop the top framebuffer
    
}
#endif
