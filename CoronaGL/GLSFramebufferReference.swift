//
//  GLSFramebufferReference.swift
//  Gravity
//
//  Created by Cooper Knaak on 2/20/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

import GLKit

public class GLSFramebufferReference: NSObject {

    weak var glkView:GLKView? = nil
    weak var buffer:GLSFrameBuffer? = nil
    public var isValid:Bool { return self.glkView !== nil || self.buffer !== nil }
    
    private init(view:GLKView?, framebuffer:GLSFrameBuffer?) {
        self.glkView = view
        self.buffer = framebuffer
        
        super.init()
    }
    
    public convenience init(view:GLKView) {
        self.init(view: view, framebuffer: nil)
    }
    
    public convenience init(framebuffer:GLSFrameBuffer) {
        self.init(view: nil, framebuffer: framebuffer)
    }
    
    convenience override init() {
        
        self.init(view: nil, framebuffer: nil)
        
    }//initialize
    
    public func bind() {
        if let view = self.glkView {
            view.bindDrawable()
        } else if let framebuffer = self.buffer {
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer.framebuffer)
        }
    }
    
    
    override public var description:String {
        if let view = self.glkView {
            return "View-\(view)"
        } else if let buf = self.buffer {
            return "Buffer-\(buf)"
        } else {
            return "Null Reference"
        }
    }
}

public func ==(lhs:GLSFramebufferReference, rhs:GLSFramebufferReference) -> Bool {
    
    if (!lhs.isValid || !rhs.isValid) {
      
        //One of them refers to the lack of a framebuffer.
        //Since I use this method to determine if I should change
        //the framebuffer, I return 'true' so the framebuffer stays the same
        return true
            
    } else if (lhs.glkView == rhs.glkView && lhs.glkView !== nil) {
        return true
    } else if (lhs.buffer == rhs.buffer && lhs.buffer !== nil) {
        return true
    }
    
    return false
}//check if two references refer to the same framebuffer