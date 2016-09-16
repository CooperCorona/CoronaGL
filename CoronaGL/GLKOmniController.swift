//
//  GLKOmniController.swift
//  Fields and Forces
//
//  Created by Cooper Knaak on 12/13/14.
//  Copyright (c) 2014 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import GLKit
import CoronaConvenience
import CoronaStructures

open class GLKOmniController: GLKViewController {
    
    open var framebufferStack:GLSFramebufferStack! = nil
    open var container:GLSNode! = nil
    open var projection:SCMatrix4 = SCMatrix4()

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        
        let glkView = self.view as! GLKView
        glkView.context = CCTextureOrganizer.sharedContext
        EAGLContext.setCurrent(CCTextureOrganizer.sharedContext)
        
        self.container = GLSNode(frame: CGRect.zero, projection: projection)
        
        self.framebufferStack = GLSFramebufferStack(initialBuffer: glkView)
        self.container.framebufferStack = self.framebufferStack
        
        let vSize = self.getFrame().size
        self.projection = SCMatrix4(right: vSize.width, top: vSize.height, back: -1024, front: 1024)
        
//        GLKOmniController.setupOpenGL()
        
        self.preferredFramesPerSecond = 30
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        
        GLKOmniController.setupOpenGL()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override open func glkView(_ view: GLKView, drawIn rect: CGRect) {
        
        glClearColor(0.2, 0.2, 0.2, 1.0)
        glClear(GLenum(GL_COLOR_BUFFER_BIT))
        
        self.container.render(SCMatrix4())
//        GLSUniversalRenderer.render()


    }//draw
    
    open func update() {
        
        let dt = CGFloat(self.timeSinceLastUpdate)
        
        self.updateContainer(dt: dt)
        

    }//update
    
    open func updateContainer(dt:CGFloat) {
        
        self.container.update(dt)
    }//update container

    
    open func calculateProjection() {
        let vSize = self.view.frame.size
        self.projection = SCMatrix4(right: vSize.width, top: vSize.height, back: -1024, front: 1024)
    }
    
    // MARK: - Positioning
    
    open func centerContainer(position:CGPoint, scale containerScale:CGFloat? = nil) -> CGPoint {
        let vSize = self.view.frame.size
        let scale = containerScale ?? self.container.scale
        return CGPoint(x: vSize.width / 2.0 - position.x, y: vSize.height / 2.0 - position.y) * scale
    }
    
    open func clampCenter(center:CGPoint, levelSize oSize:CGSize, minBoundary:CGFloat, maxBoundary:CGFloat, hudHeight:CGFloat, scale containerScale:CGFloat? = nil) -> CGPoint {
        
        let scale = containerScale ?? self.container.scale
        let vSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height - hudHeight)
        let lSize = oSize * scale
        
        let oBounds = (max: maxBoundary, min: minBoundary)
        let oFrame = CGRect(x: oBounds.min, y: 0.0, width: oBounds.max - oBounds.min, height: oSize.height)

        let maxYSubtractionTerm = oFrame.minY * scale + hudHeight * (scale - 1.0) / 2.0
        let maxX = vSize.width  * (scale - 1.0) / 2.0 - oFrame.minX * scale
        let maxY = vSize.height * (scale - 1.0) / 2.0 - maxYSubtractionTerm
        let minX = vSize.width  * (scale + 1.0) / 2.0 - oFrame.maxX * scale
        let minY = vSize.height * (scale + 1.0) / 2.0 - oFrame.maxY * scale
        
        let xpos:CGFloat
        if (lSize.width <= vSize.width) {
            xpos = scale * (vSize.width - oSize.width) / 2.0
        } else {
            xpos = min(max(center.x, minX), maxX)
        }
        let ypos:CGFloat
        if (lSize.height <= vSize.height) {
            ypos = scale * (vSize.height - oSize.height) / 2.0
        } else {
            ypos = min(max(center.y, minY), maxY)
        }
        return CGPoint(x: xpos, y: ypos)
    }
    
    open func convertPointToOpenGL(point: CGPoint) -> CGPoint {
        return self.convertPointToOpenGL(point: point, container: self.container)
        /*
        var glPoint = point
        let vSize = self.view.frame.size
        glPoint = CGPoint(x: glPoint.x, y: vSize.height - glPoint.y)
        
        let cSize  = self.container.contentSize
        let anchor = self.container.anchor
        let scale  = self.container.scale
        
        let cx = self.container.position.x - cSize.width  * anchor.x * scale
        let cy = self.container.position.y - cSize.height * anchor.y * scale
        
        return CGPoint(x: (glPoint.x - cx) / scale, y: (glPoint.y - cy) / scale)
        */
    }//convert point to OpenGL
    
    open func convertPointFromOpenGL(point:CGPoint) -> CGPoint {
        return self.convertPointFromOpenGL(point: point, container: self.container)
        /*
        let scale = self.container.scale
        let c = self.container.position - self.container.anchor * self.container.contentSize * scale
        let location = point * scale + c
        return CGPoint(x: location.x, y: self.view.frame.size.height - location.y)
        */
    }//conver point from OpenGL coords to UIKit coords
    
    open func convertPointToOpenGL(point: CGPoint, container:GLSNode) -> CGPoint {
        
        var glPoint = point
        let vSize = self.view.frame.size
        glPoint = CGPoint(x: glPoint.x, y: vSize.height - glPoint.y)
        
        let cSize  = container.contentSize
        let anchor = container.anchor
        let scale  = container.scale
        
        let cx = container.position.x - cSize.width  * anchor.x * scale
        let cy = container.position.y - cSize.height * anchor.y * scale
        
        return CGPoint(x: (glPoint.x - cx) / scale, y: (glPoint.y - cy) / scale)
    }//convert point to OpenGL
    
    open func convertPointFromOpenGL(point:CGPoint, container:GLSNode) -> CGPoint {
        let scale = CGPoint(x: container.scaleX, y: container.scaleY)
        let c = container.position - container.anchor * container.contentSize * scale
        let location = point * scale + c
        return CGPoint(x: location.x, y: self.view.frame.size.height - location.y)
    }//conver point from OpenGL coords to UIKit coords
    
    open func openGLPointFromTouches(touches:Set<UITouch>) -> CGPoint {
        return self.convertPointToOpenGL(point: self.locationFromTouches(touches: touches as NSSet))
    }
    
    open func openGLPointFromTouches(touches:Set<UITouch>, container:GLSNode) -> CGPoint {
        return self.convertPointToOpenGL(point: self.locationFromTouches(touches: touches as NSSet), container: container)
    }
    
    ///We can't use dispatch_once in Swift 3, which is fine
    ///for most of the singletons (which were holdovers from
    ///Swift 1 anyways), but we actually need it here. Instead,
    ///we have a (lazy) static variable that is initialized via
    ///closure. That closure performs our setup. The setupOpenGL
    ///method just loads this value, running the closure.
    fileprivate static let setupOpenGLClosure:Bool = {
        let cctOrg = CCTextureOrganizer.sharedInstance
        cctOrg.files = [ "Atlases" ]
        cctOrg.loadTextures()
        
        //            ShaderHelper.sharedInstance.loadPrograms(["Basic Shader":"BasicShader", "Universal 2D Shader":"Universal2DShader", "Universal Particle Shader":"UniversalParticleShader", "Noise Shader":"NoiseShader"])
        ShaderHelper.sharedInstance.loadProgramsFromBundle()
        return true
    }()
    open class func setupOpenGL() {
        let _ = GLKOmniController.setupOpenGLClosure
    }//setup OpenGL
    
}
#endif
