//
//  PlaygroundOpenGLDelegate.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 12/5/15.
//  Copyright © 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import GLKit
import CoronaConvenience
import CoronaStructures
    
///For the love of all that is holy, only ever use this in a playground!
public class PlaygroundOpenGLDelegate: NSObject, GLKViewDelegate {
    
    public let view:GLKView
    public let framebufferStack:GLSFramebufferStack
    public var clearColor = SCVector4(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
    public let container = GLSNode(position: CGPoint.zero, size: CGSize.zero)
    public let projection:SCMatrix4
    
    public init(doLog:Bool = false) {
        if doLog {
            print("Setting up OpenGL...")
        }
        EAGLContext.setCurrentContext(CCTextureOrganizer.sharedContext)
        ShaderHelper.sharedInstance.loadPrograms([
            "Basic Shader":"BasicShader",
            "Universal 2D Shader":"Universal2DShader",
            "Universal Particle Shader":"UniversalParticleShader",
            "Noise Shader":"NoiseShader",
            "Double Shader":"DoubleShader",
            "Dummy Shader":"DummyShader",
            "Dummy Shader 2":"DummyShader ES 3",
            "Radial Gradient Shader":"RadialGradientShader",
            "Perlin Noise Shader":"PerlinNoiseShader",
            "Perlin Fractal Noise Shader":"PerlinFractalNoiseShader",
            "Perlin Abs Noise Shader":"PerlinAbsNoiseShader",
            "Perlin Sin Noise Shader":"PerlinSinNoiseShader",
            "Fire Shader":"FireShader",
            "Repeated Noise Shader":"RepeatedNoiseShader"
            ])
        
        if doLog {
            print("Shaders setup...")
        }
        
        let tOrg = CCTextureOrganizer.sharedInstance
        tOrg.files = ["Atlases"]
        tOrg.loadTextures()
        
        if doLog {
            print("Textures setup...")
        }
        
        let proj = SCMatrix4(right: 768.0, top: 1024.0, back: -1024.0, front: 1024.0)
//        GLSUniversalRenderer.sharedInstance.projection = proj
        GLSNode.universalProjection = proj
        self.projection = proj
        let vSize = CGSize(width: 768, height: 1024)
        let v = GLKView(frame: CGRect(size: vSize), context: CCTextureOrganizer.sharedContext)
        let fStack = GLSFramebufferStack(initialBuffer: v)
        
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        //    XCPSetExecutionShouldContinueIndefinitely(true)
        
        if doLog {
            print("Misc setup...")
        }
        
        self.view = v
        self.framebufferStack = fStack
        
        super.init()
        
        v.delegate = self
    }
    
    public func glkView(view: GLKView, drawInRect rect: CGRect) {
        self.clearColor.bindGLClearColor()
        self.container.render()
    }
    
}
#endif