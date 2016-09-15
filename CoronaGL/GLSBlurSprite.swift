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
public class GLSBlurSprite: GLSSprite, DoubleBuffered {
    
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
    ///DoubleBuffered Conformance. Returns verticalBuffer,
    ///because that is the buffer that contains the final texture.
    public var buffer:GLSFrameBuffer { return self.verticalBuffer }
    
    public var shouldRedraw = true
    public var bufferIsDirty = false
    
    ///What type of blur to use (changes shader program).
    public var blurType:BlurType = .FastBlur {
        didSet {
            if self.blurType != oldValue {
                switch self.blurType {
                case .FastBlur:
                    self.blurProgram = ShaderHelper.programDictionaryForString("Fast Blur Shader")!
                case .HardBlur:
                    self.blurProgram = ShaderHelper.programDictionaryForString("Hard Blur Shader")!
                case .SoftBlur:
                    self.blurProgram = ShaderHelper.programDictionaryForString("Soft Blur Shader")!
                }
                if self.shouldRedraw {
                    self.renderToTexture()
                }
            }
        }
    }
    private var blurProgram = ShaderHelper.programDictionaryForString("Fast Blur Shader")!
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
            if self.shouldRedraw && !(self.blurFactor ~= oldValue) {
                self.renderToTexture()
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
        
        let dVecX:CGFloat = horizontal ? 1.0 : 0.0
        let dVecY:CGFloat = horizontal ? 0.0 : 1.0
        
        self.blurProgram.use()
        
        if horizontal {
            glBufferData(GLenum(GL_ARRAY_BUFFER), self.horizontalBlurVertices.size, self.horizontalBlurVertices.vertices, GLenum(GL_STATIC_DRAW))
        } else {
            glBufferData(GLenum(GL_ARRAY_BUFFER), self.verticalBlurVertices.size, self.verticalBlurVertices.vertices, GLenum(GL_STATIC_DRAW))
        }
        
        self.blurProgram.uniformMatrix4fv("u_Projection", matrix: self.projection)
        
        self.blurProgram.uniform1f("u_BlurFactor", value: self.blurFactor)
        self.blurProgram.uniform2f("u_Size", value: self.contentSize.getCGPoint())
        self.blurProgram.uniform2f("u_DirectionVector", value: CGPoint(x: dVecX, y: dVecY))
        
        if horizontal {
            self.pushTexture(self.blurTexture?.name ?? 0, atLocation: self.blurProgram["u_TextureInfo"])
        } else {
            self.pushTexture(self.horizontalBuffer.ccTexture.name, atLocation: self.blurProgram["u_TextureInfo"])
        }
        self.blurProgram.enableAttributes()
        //Stride for both horizontal & vertical is same
        self.blurProgram.bridgeAttributesWithSizes([2, 2], stride: self.horizontalBlurVertices.stride)
        
        //Count for both horizontal & vertical is same
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.horizontalBlurVertices.count))
        
        self.blurProgram.disable()
        self.popTextures()
        self.framebufferStack?.popFramebuffer()
    }//render to framebuffer
    
    ///Renders the blurred textures to the background buffers.
    public func renderToTexture() {
        self.renderToBuffer(self.horizontalBuffer, horizontal: true)
        self.renderToBuffer(self.verticalBuffer, horizontal: false)
        self.bufferIsDirty = false
    }//render to textures
    
    private func blurTextureChanged() {
        
        let frame = self.blurTexture?.frame ?? CGRect(square: 1.0)
        
        self.horizontalBlurVertices.alterWithFrame(frame) { point, vertex in
            vertex.texture = point.getGLTuple()
            return
        }
    }//blur texture changed
    
}
