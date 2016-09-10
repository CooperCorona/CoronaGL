//
//  GLSBlurSprite.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 6/7/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience

///Code for shader and coefficents for .FastBlur comes from http://xissburg.com/faster-gaussian-blur-in-glsl/
public class GLSBlurSprite: GLSSprite {
    
    // MARK: - Types
    
    public enum BlurType: String, CustomStringConvertible {
        case FastBlur = "Fast Blur"
        case SoftBlur = "Soft Blur"
        case HardBlur = "Hard Blur"
        
        public init?(integer:Int) {
            
            switch integer {
            case 0:
                self = .FastBlur
            case 1:
                self = .SoftBlur
            case 2:
                self = .HardBlur
            default:
                return nil
            }
        }
        
        public var description:String { return self.rawValue }
    }
    
    private class BlurProgram: GLAttributeBridger {
        
        let type:BlurType
        
        let u_Projection:GLint
        let u_DirectionVector:GLint
        let u_Size:GLint
        let u_BlurFactor:GLint
        let u_TextureInfo:GLint
        let a_Position:GLint
        let a_Texture:GLint
        
        init(type:BlurType) {
            
            let program:GLuint
            
            self.type = type
            switch self.type {
            case .FastBlur:
                program = ShaderHelper.programForString("Fast Blur Shader")!
            case .SoftBlur:
                program = ShaderHelper.programForString("Soft Blur Shader")!
            case .HardBlur:
                program = ShaderHelper.programForString("Hard Blur Shader")!
            }
            
            self.u_Projection = glGetUniformLocation(program, "u_Projection")
            self.u_DirectionVector = glGetUniformLocation(program, "u_DirectionVector")
            self.u_TextureInfo = glGetUniformLocation(program, "u_TextureInfo")
            self.u_Size = glGetUniformLocation(program, "u_Size")
            self.u_BlurFactor = glGetUniformLocation(program, "u_BlurFactor")
            self.a_Position = glGetAttribLocation(program, "a_Position")
            self.a_Texture = glGetAttribLocation(program, "a_Texture")
            
            super.init(program: program)
            
            let atts = [self.a_Position, self.a_Texture]
            self.addAttributes(atts)
        }
        
    }
    
    // MARK: - Properties
    
    ///The texture to blur
    public var blurTexture:CCTexture? = nil {
        didSet {
            self.blurTextureChanged()
        }
    }
    ///The framebuffer that contains the horizontally blurred texture.
    public let horizontalBuffer:GLSFrameBuffer
    ///The framebuffer that contains the totally blurred texture.
    public let verticalBuffer:GLSFrameBuffer
    
    ///What type of blur to use (changes shader program).
    public var blurType:BlurType = .FastBlur {
        didSet {
            if self.blurType != oldValue {
                self.blurProgram = BlurProgram(type: self.blurType)
            }
        }
    }
    private var blurProgram = BlurProgram(type: .FastBlur)
    private let horizontalBlurVertices  = TexturedQuadVertices(vertex: UVertex())
    private let verticalBlurVertices    = TexturedQuadVertices(vertex: UVertex())
    
    /**
    How blurry the texture should be. Animatable.
    
    In .FastBlur mode, this controls how far away
    the shader reads pixels for blurring.
    
    In .SoftBlur or .HardBlur, this is directly
    how much blur there is. At 0.0, the texture is
    not blurred at all. At 1.0, the texture is maximally blurred.
    */
    public var blurFactor:CGFloat = 2.0 {
        didSet {
            if self.inAnimationBlock {
                self.add1Animation(oldValue, end: self.blurFactor) { [unowned self] in self.blurFactor = $0 }
                self.blurFactor = oldValue
            }
        }
    }
    
    // MARK: - Setup
    
    ///Initialize a GLSBlurSprite object with a size and a texture to blur.
    public init(size:CGSize, texture:CCTexture?) {
        
        self.blurTexture = texture
        
        self.horizontalBuffer = GLSFrameBuffer(size: size)
        self.verticalBuffer = GLSFrameBuffer(size: size)
        
        let sap = size.getCGPoint()
        self.horizontalBlurVertices.iterateWithHandler() { index, vertex in
            let pos = TexturedQuad.pointForIndex(index)
            vertex.position = (pos * sap).getGLTuple()
            vertex.texture = pos.getGLTuple()
        }
        
        super.init(position:CGPoint.zero, size: size, texture: self.verticalBuffer.ccTexture)
        
        self.verticalBlurVertices.iterateWithHandler() { index, vertex in
            vertex = self.horizontalBlurVertices[index]
            return
        }
        
        self.blurTextureChanged()
    }
    
    // MARK: - Logic
    
    private func renderToBuffer(buffer:GLSFrameBuffer, horizontal:Bool) {
        
        self.framebufferStack?.pushGLSFramebuffer(buffer)
        
        buffer.bindClearColor()
        
        let dVecX:GLfloat = horizontal ? 1.0 : 0.0
        let dVecY:GLfloat = horizontal ? 0.0 : 1.0
        
        glUseProgram(self.blurProgram.program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.blurProgram.vertexBuffer)
        
        if horizontal {
            glBufferData(GLenum(GL_ARRAY_BUFFER), self.horizontalBlurVertices.size, self.horizontalBlurVertices.vertices, GLenum(GL_STATIC_DRAW))
        } else {
            glBufferData(GLenum(GL_ARRAY_BUFFER), self.verticalBlurVertices.size, self.verticalBlurVertices.vertices, GLenum(GL_STATIC_DRAW))
        }
//        let proj = GLSUniversalRenderer.sharedInstance.projection
        let proj = self.projection
        glUniformMatrix4fv(self.blurProgram.u_Projection, 1, 0, proj.values)
        
        glUniform1f(self.blurProgram.u_BlurFactor, GLfloat(self.blurFactor))
        glUniform2f(self.blurProgram.u_Size, GLfloat(self.contentSize.width), GLfloat(self.contentSize.height))
        glUniform2f(self.blurProgram.u_DirectionVector, dVecX, dVecY)
        
        if horizontal {
            self.pushTexture(self.blurTexture?.name ?? 0, atLocation: self.blurProgram.u_TextureInfo)
        } else {
            self.pushTexture(self.horizontalBuffer.ccTexture.name, atLocation: self.blurProgram.u_TextureInfo)
        }
        self.blurProgram.enableAttributes()
        //Stride for both horizontal & vertical is same
        self.blurProgram.bridgeAttributesWithSizes([2, 2], stride: self.horizontalBlurVertices.stride)
        
        //Count for both horizontal & vertical is same
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.horizontalBlurVertices.count))
        
        
        self.blurProgram.disableAttributes()
        self.popTextures()
        self.framebufferStack?.popFramebuffer()
    }//render to framebuffer
    
    ///Renders the blurred textures to the background buffers.
    public func renderToTextures() {
        
        self.renderToBuffer(self.horizontalBuffer, horizontal: true)
        self.renderToBuffer(self.verticalBuffer, horizontal: false)
        
    }//render to textures
    
    private func blurTextureChanged() {
        
        let frame = self.blurTexture?.frame ?? CGRect(square: 1.0)
        
        self.horizontalBlurVertices.alterWithFrame(frame) { point, vertex in
            vertex.texture = point.getGLTuple()
            return
        }
    }//blur texture changed
    
}
