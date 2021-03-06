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
    private(set) open var container = GLSNode(position: NSPoint.zero, size: NSSize.zero)
    private(set) open lazy var framebufferStack:GLSFramebufferStack = GLSFramebufferStack(initialBuffer: self)
    
    private(set) open var buffers:[DoubleBuffered] = []
    
    // MARK: - Setup
    
    public override init?(frame frameRect: NSRect, pixelFormat format: NSOpenGLPixelFormat?) {
        super.init(frame: frameRect, pixelFormat: format)
        
        guard let format = format else {
            return nil
        }
        //  Create a context with our pixel format (we have no other context, so nil)
        guard let context = NSOpenGLContext(format: format, share: GLSFrameBuffer.globalContext) else {
            Swift.print("context could not be constructed")
            return nil
        }
        self.openGLContext = context
        self.openGLContext?.makeCurrentContext()
        context.view = self
        
        self.container.framebufferStack = self.framebufferStack
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        let attrs: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFAAccelerated),            //  Use accelerated renderers
            UInt32(NSOpenGLPFAColorSize), UInt32(32),  //  Use 32-bit color
            UInt32(NSOpenGLPFAOpenGLProfile),          //  Use version's >= 3.2 core
            UInt32(NSOpenGLProfileVersion3_2Core),
            UInt32(0)                                  //  C API's expect to end with 0
        ]
        
        // Create a pixel format using our attributes
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
    
    public class func setViewport(to size:NSSize) {
        glViewport(0, 0, GLsizei(size.width), GLsizei(size.height))
        GLSNode.universalProjection = SCMatrix4(right: size.width, top: size.height)
        
        //The GLSFrameBuffer context does not update when the
        //previous code is called because it is not the current
        //context, so we need to set the viewport in terms
        //of the GLSFrameBuffer.globalContext, too. For some reason,
        //resizing the window (thus calling reshape and then this method)
        //fixes the issue, so I don't know where the viewport is being
        //set elsewhere (or maybe it's just off by one and is imperceptible).
        GLSFrameBuffer.globalContext.makeCurrentContext()
        glViewport(0, 0, GLsizei(size.width), GLsizei(size.height))
    }
    
    open override func reshape() {
        super.reshape()
        OmniGLView2d.setViewport(to: self.frame.size)
    }
    
    // MARK: - Logic
    
    open override func draw(_ dirtyRect: NSRect) {
        GLSFrameBuffer.globalContext.view = self
        self.openGLContext?.makeCurrentContext()
        for buffer in self.buffers {
            buffer.renderToTexture()
        }
        GLSNode.universalProjection = SCMatrix4(right: self.frame.width, top: self.frame.height)
        self.clearColor.bindGLClearColor()
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        self.container.render()
        glFlush()
        self.openGLContext?.flushBuffer()
    }
    
    // MARK: - Children
    
    open func addChild(_ child:GLSNode) {
        self.container.addChild(child)
        self.setNeedsDisplay(self.frame)
    }
    
    @discardableResult open func removeChild(_ child:GLSNode) -> GLSNode? {
        let node = self.container.removeChild(child)
        self.setNeedsDisplay(self.frame)
        return node
    }
    
    open func add(buffer:DoubleBuffered) {
        self.buffers.append(buffer)
        if let node = buffer as? GLSNode {
            node.framebufferStack = self.framebufferStack
        }
    }
    
    open func removeBuffer(at index:Int) -> DoubleBuffered? {
        guard 0 <= index && index < self.buffers.count else {
            return nil
        }
        return self.buffers.remove(at: index)
    }
    
}
#endif
