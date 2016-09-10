//
//  GLSFramebufferStack.swift
//  Fields and Forces
//
//  Created by Cooper Knaak on 1/9/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

import GLKit

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
        
        return self.pushFramebuffer(buffer.framebuffer)
        
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
