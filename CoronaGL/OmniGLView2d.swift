//
//  OmniGLView2d.swift
//  NoisyImagesOSX
//
//  Created by Cooper Knaak on 3/29/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

#if os(OSX)
import AppKit
import GLKit
import CoronaConvenience
import CoronaStructures
import OpenGL

open class OmniGLView2d: NSOpenGLView {
    
    open var clearColor = SCVector4.blackColor
    open private(set) var container = GLSNode(position: NSPoint.zero, size: NSSize.zero)
    private(set) lazy var framebufferStack:GLSFramebufferStack = GLSFramebufferStack(initialBuffer: self)
    
    // MARK: - Setup
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        let attrs: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFAAccelerated),            //  Use accelerated renderers
            UInt32(NSOpenGLPFAColorSize), UInt32(32),  //  Use 32-bit color
            UInt32(NSOpenGLPFAOpenGLProfile),          //  Use version's >= 3.2 core
            UInt32(NSOpenGLProfileVersion3_2Core),
            UInt32(0)                                  //  C API's expect to end with 0
        ]
        
        //  Create a pixel format using our attributes
        guard let pixelFormat = NSOpenGLPixelFormat(attributes: attrs) else {
            Swift.print("pixelFormat could not be constructed")
            return
        }
        self.pixelFormat = pixelFormat
        
        //  Create a context with our pixel format (we have no other context, so nil)
        guard let context = NSOpenGLContext(format: pixelFormat, share: GLSFrameBuffer.globalContext) else {
            Swift.print("context could not be constructed")
            return
        }
        self.openGLContext = context
        self.openGLContext?.makeCurrentContext()
        context.view = self
        
        self.container.framebufferStack = self.framebufferStack
    }
    
    fileprivate static var __once:Void = {
        ShaderHelper.sharedInstance.loadProgramsFromBundle()
        CCTextureOrganizer.sharedInstance.files = ["Atlases"]
        CCTextureOrganizer.sharedInstance.loadTextures()
    }()
    open class func setupOpenGL() {
        let _ = __once
    }
    
    open override func prepareOpenGL() {
        super.prepareOpenGL()
        
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
    }
    
    open override func reshape() {
        super.reshape()
        glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        GLSNode.universalProjection = SCMatrix4(right: self.frame.width, top: self.frame.height)
    }
    
    // MARK: - Logic
    
    open override func draw(_ dirtyRect: NSRect) {
        self.openGLContext?.makeCurrentContext()
        self.clearColor.bindGLClearColor()
        self.container.render()
        glFlush()
        self.openGLContext?.flushBuffer()
    }
    
    // MARK: - Children
    
    open func addChild(_ child:GLSNode) {
        self.container.addChild(child)
        self.setNeedsDisplay(self.frame)
    }
    
    open func removeChild(_ child:GLSNode) -> GLSNode? {
        let node = self.container.removeChild(child)
        self.setNeedsDisplay(self.frame)
        return node
    }
    
}
#endif
