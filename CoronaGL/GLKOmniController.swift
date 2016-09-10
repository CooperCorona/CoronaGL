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

public class GLKOmniController: GLKViewController {
    
    public var framebufferStack:GLSFramebufferStack! = nil
    public var container:GLSNode! = nil
    public var projection:SCMatrix4 = SCMatrix4()

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        
        let glkView = self.view as! GLKView
        glkView.context = CCTextureOrganizer.sharedContext
        EAGLContext.setCurrentContext(CCTextureOrganizer.sharedContext)
        
        self.container = GLSNode(frame: CGRectZero, projection: projection)
        
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
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override public func glkView(view: GLKView, drawInRect rect: CGRect) {
        
        glClearColor(0.2, 0.2, 0.2, 1.0)
        glClear(GLenum(GL_COLOR_BUFFER_BIT))
        
        self.container.render(SCMatrix4())
//        GLSUniversalRenderer.render()


    }//draw
    
    public func update() {
        
        let dt = CGFloat(self.timeSinceLastUpdate)
        
        self.updateContainer(dt)
        

    }//update
    
    public func updateContainer(dt:CGFloat) {
        
        self.container.update(dt)
    }//update container

    
    public func calculateProjection() {
        let vSize = self.view.frame.size
        self.projection = SCMatrix4(right: vSize.width, top: vSize.height, back: -1024, front: 1024)
    }
    
    // MARK: - Positioning
    
    public func centerContainer(position:CGPoint, scale containerScale:CGFloat? = nil) -> CGPoint {
        let vSize = self.view.frame.size
        let scale = containerScale ?? self.container.scale
        return CGPoint(x: vSize.width / 2.0 - position.x, y: vSize.height / 2.0 - position.y) * scale
    }
    
    public func clampCenter(center:CGPoint, levelSize oSize:CGSize, minBoundary:CGFloat, maxBoundary:CGFloat, hudHeight:CGFloat, scale containerScale:CGFloat? = nil) -> CGPoint {
        
        let scale = containerScale ?? self.container.scale
        let vSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height - hudHeight)
        let lSize = oSize * scale
        
        let oBounds = (max: maxBoundary, min: minBoundary)
        let oFrame = CGRect(x: oBounds.min, y: 0.0, width: oBounds.max - oBounds.min, height: oSize.height)

        let maxX = vSize.width  * (scale - 1.0) / 2.0 - oFrame.minX * scale
        let maxY = vSize.height * (scale - 1.0) / 2.0 - oFrame.minY * scale + hudHeight * (scale - 1.0) / 2.0
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
    
    public func convertPointToOpenGL(point: CGPoint) -> CGPoint {
        return self.convertPointToOpenGL(point, container: self.container)
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
    
    public func convertPointFromOpenGL(point:CGPoint) -> CGPoint {
        return self.convertPointFromOpenGL(point, container: self.container)
        /*
        let scale = self.container.scale
        let c = self.container.position - self.container.anchor * self.container.contentSize * scale
        let location = point * scale + c
        return CGPoint(x: location.x, y: self.view.frame.size.height - location.y)
        */
    }//conver point from OpenGL coords to UIKit coords
    
    public func convertPointToOpenGL(point: CGPoint, container:GLSNode) -> CGPoint {
        
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
    
    public func convertPointFromOpenGL(point:CGPoint, container:GLSNode) -> CGPoint {
        let scale = CGPoint(x: container.scaleX, y: container.scaleY)
        let c = container.position - container.anchor * container.contentSize * scale
        let location = point * scale + c
        return CGPoint(x: location.x, y: self.view.frame.size.height - location.y)
    }//conver point from OpenGL coords to UIKit coords
    
    public func openGLPointFromTouches(touches:Set<UITouch>) -> CGPoint {
        return self.convertPointToOpenGL(self.locationFromTouches(touches))
    }
    
    public func openGLPointFromTouches(touches:Set<UITouch>, container:GLSNode) -> CGPoint {
        return self.convertPointToOpenGL(self.locationFromTouches(touches), container: container)
    }
    
    
    public class func setupOpenGL() {
        struct StaticOnceToken {
            static var onceToken:dispatch_once_t = 0;
        }
        
        dispatch_once(&StaticOnceToken.onceToken) {
            let cctOrg = CCTextureOrganizer.sharedInstance
            cctOrg.files = [ "Atlases" ]
            cctOrg.loadTextures()
            
//            ShaderHelper.sharedInstance.loadPrograms(["Basic Shader":"BasicShader", "Universal 2D Shader":"Universal2DShader", "Universal Particle Shader":"UniversalParticleShader", "Noise Shader":"NoiseShader"])
            ShaderHelper.sharedInstance.loadProgramsFromBundle()
        }//dispatch only one time
        
    }//setup OpenGL
    
}
#endif