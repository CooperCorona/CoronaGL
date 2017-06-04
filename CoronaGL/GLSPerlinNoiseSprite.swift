//
//  GLSPerlinNoiseSprite.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 5/27/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

import GLKit
import CoronaConvenience
import CoronaStructures

public protocol DoubleBuffered {
    var buffer:GLSFrameBuffer { get }
    var shouldRedraw:Bool { get set }
    var bufferIsDirty:Bool { get }
    func renderToTexture()
    
}

open class GLSPerlinNoiseSprite: GLSSprite, DoubleBuffered {
    
    // MARK: - Types
    
    public struct PerlinNoiseVertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var texture:(GLfloat, GLfloat)  = (0.0, 0.0)
        public var noiseTexture:(GLfloat, GLfloat, GLfloat) = (0.0, 0.0, 0.0)
//        var aspectRatio:(GLfloat, GLfloat) = (0.0, 0.0)
    }
    
    public enum NoiseType: String {
        case Default    = "Default"
        case Fractal    = "Fractal"
        case Abs        = "Abs"
        case Sin        = "Sin"
    }
    
    // MARK: - Properties
    
    fileprivate var noiseProgram = ShaderHelper.programDictionaryForString("Perlin Noise Shader")!
    
    ///Texture used to find, generate, and interpolate between noise values.
    open var noiseTexture:Noise3DTexture2D
    ///Gradient of colors that noise is mapped to.
    open var gradient:GLGradientTexture2D
    ///Texture multiplied into the final output color.
    open var shadeTexture:CCTexture? {
        didSet {
            self.shadeTextureChanged()
        }
    }
    
    open let noiseVertices:TexturedQuadVertices<PerlinNoiseVertex> = []
    open fileprivate(set) var buffer:GLSFrameBuffer
    
    ///What type of noise is drawn (Default, Fractal, etc.)
    open var noiseType:NoiseType = NoiseType.Default {
        didSet {
            let key:String
            switch self.noiseType {
            case .Default:
                key = "Perlin Noise Shader"
            case .Fractal:
                key = "Perlin Fractal Noise Shader"
            case .Abs:
                key = "Perlin Abs Noise Shader"
            case .Sin:
                key = "Perlin Sin Noise Shader"
            }
            self.noiseProgram = ShaderHelper.programDictionaryForString(key)!
            self.bufferIsDirty = true
        }
    }
    
    ///Conceptually, the size of the noise. How much noise you can see.
    open var noiseSize:CGSize = CGSize(square: 1.0) {
        didSet {
            self.noiseSizeChanged()
            if self.shouldRedraw && !(noiseSize.width ~= oldValue.width || noiseSize.height ~= oldValue.height) {
                self.renderToTexture()
            } else {
                self.bufferIsDirty = true
            }
        }
    }
    ///Accessor for *noiseSize.width*
    open var noiseWidth:CGFloat {
        get {
            return self.noiseSize.width
        }
        set {
            self.noiseSize.width = newValue
        }
    }
    ///Accessor for *noiseSize.height*
    open var noiseHeight:CGFloat {
        get {
            return self.noiseSize.height
        }
        set {
            self.noiseSize.height = newValue
        }
    }
    
    ///Offset of noise texture. Note that the texture is not redrawn when *offset* is changed.
    open var offset:SCVector3 = SCVector3() {
        didSet {
            self.offset = SCVector3(x: self.offset.x.truncatingRemainder(dividingBy: CGFloat(self.period.x)), y: self.offset.y.truncatingRemainder(dividingBy: CGFloat(self.period.y)), z: self.offset.z.truncatingRemainder(dividingBy: CGFloat(self.period.z)))
            if self.shouldRedraw && !(self.offset ~= oldValue) {
                self.renderToTexture()
            } else {
                self.bufferIsDirty = true
            }
        }
    }
    ///Speed at with offset changes. Note that the texture is not redrawn when *offset* is changed.
    open var offsetVelocity = SCVector3()
    ///How much the noise is blended with the rest of the texture. 0.0 for no noise and 1.0 for full noise.
    open var noiseAlpha:CGFloat = 1.0
    
    ///The period is how long it takes for the noise to begin repeating. Defaults to 256 (which doesn't actually have an effect).
    open var period:(x:Int, y:Int, z:Int) = (256, 256, 256) {
        didSet {
            self.bufferIsDirty = true
        }
    }
    open var xyPeriod:(x:Int, y:Int) {
        get {
            return (self.period.x, self.period.y)
        }
        set {
            self.period = (newValue.x, newValue.y, self.period.z)
        }
    }
    open var yzPeriod:(y:Int, z:Int) {
        get {
            return (self.period.y, self.period.z)
        }
        set {
            self.period = (self.period.x, newValue.y, newValue.z)
        }
    }
    open var xzPeriod:(x:Int, z:Int) {
        get {
            return (self.period.x, self.period.z)
        }
        set {
            self.period = (newValue.x, self.period.y, newValue.z)
        }
    }
    
    /**
    What to divide the 3D Noise Value by.
    
    Since perlin noise actually returns values
    in the range [-0.7, 0.7] (according to http://paulbourke.net/texture_colour/perlin/ ),
    I don't get the full range of the gradient. Thus,
    by adding a divisor, I can scale the noise to
    the full range. Default value is 0.7, because
    that should cause noise to range from [-1.0, 1.0].
    */
    open var noiseDivisor:CGFloat = 0.7 {
        didSet {
            if self.noiseDivisor <= 0.0 {
                self.noiseDivisor = 1.0
            }
            self.bufferIsDirty = true
        }
    }
    
    open var noiseAngle:CGFloat = 0.0 {
        didSet {
            self.noiseAngle = self.noiseAngle.truncatingRemainder(dividingBy: CGFloat(2.0 * M_PI))
            self.bufferIsDirty = true;
        }
    }
    
    open var shouldRedraw = false
    open fileprivate(set) var bufferIsDirty = false
    
    open fileprivate(set) var fadeAnimation:NoiseFadeAnimation? = nil
    
    // MARK: - Setup
    
    public init(size:CGSize, texture:CCTexture?, noise:Noise3DTexture2D, gradient:GLGradientTexture2D) {
        
        self.buffer = GLSFrameBuffer(size: size)
        self.shadeTexture = texture
        self.noiseTexture = noise
        self.gradient = gradient
        
//        var p:[GLint] = []
        /*for cur in self.noiseTexture.noise.permutations {
        p.append(GLint(cur))
        }*/
        /*let perms = self.noiseTexture.noise.permutations
        for iii in 0..<1028 {
        let cur = perms[iii % perms.count]
        p.append(GLint(cur))
        }
        self.permutations = p*/
        
        for _ in 0..<TexturedQuad.verticesPerQuad {
            self.noiseVertices.append(PerlinNoiseVertex())
        }
        
        //        super.init(position: CGPoint.zero, size: size)
        super.init(position: size.center, size: size, texture: self.buffer.ccTexture)
        
        let sizeAsPoint = size.getCGPoint()
        self.noiseVertices.iterateWithHandler() { index, vertex in
            let curPoint = TexturedQuad.pointForIndex(index)
            vertex.texture = curPoint.getGLTuple()
            vertex.position = (curPoint * sizeAsPoint).getGLTuple()
            
            vertex.noiseTexture = (vertex.texture.0, vertex.texture.1, 0.0)
            
//            vertex.aspectRatio = (curPoint * CGPoint(x: 1.0, y: size.height / size.width)).getGLTuple()
            return
        }
        
//        self.noiseTextureChanged()
        self.shadeTextureChanged()
    }
    
    // MARK: - Logic
    
    open override func update(_ dt: CGFloat) {
        super.update(dt)
        
        self.offset += self.offsetVelocity * dt
        
        if let fadeAnimation = self.fadeAnimation {
            fadeAnimation.update(dt)
            if fadeAnimation.isFinished {
                fadeAnimation.completionHandler?()
                self.fadeAnimation = nil
            }
        }
    }//update
    
    ///Render noise to background texture (*buffer*).
    open func renderToTexture() {
        guard let success = self.framebufferStack?.pushGLSFramebuffer(buffer: self.buffer) , success else {
            print("Error: Couldn't push framebuffer!")
            print("Stack: \(self.framebufferStack)")
            return
        }
        
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        self.noiseProgram.use()
        glBufferData(GLenum(GL_ARRAY_BUFFER), self.noiseVertices.size, self.noiseVertices.vertices, GLenum(GL_STATIC_DRAW))
        
        let proj = self.projection
        self.noiseProgram.uniformMatrix4fv("u_Projection", matrix: proj)
        
        glUniform1i(self.noiseProgram["u_TextureInfo"], 0)
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.shadeTexture?.name ?? 0)
        
        glUniform1i(self.noiseProgram["u_NoiseTextureInfo"], 1)
        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.noiseTexture.noiseTexture)
        
        glUniform1i(self.noiseProgram["u_GradientInfo"], 2)
        glActiveTexture(GLenum(GL_TEXTURE2))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.gradient.textureName)
        
        glUniform1i(self.noiseProgram["u_PermutationInfo"], 3)
        glActiveTexture(GLenum(GL_TEXTURE3))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.noiseTexture.permutationTexture)
        
        self.noiseProgram.uniform3f("u_Offset", value: self.offset)
        glUniform1f(self.noiseProgram["u_NoiseDivisor"], GLfloat(self.noiseDivisor))
        glUniform1f(self.noiseProgram["u_Alpha"], GLfloat(self.noiseAlpha))
        glUniform3i(self.noiseProgram["u_Period"], GLint(self.period.x), GLint(self.period.y), GLint(self.period.z))
        
        if (self.noiseType == .Sin) {
            glUniform1f(self.noiseProgram["u_NoiseAngle"], GLfloat(self.noiseAngle))
        }
        
        self.noiseProgram.enableAttributes()
        self.noiseProgram.bridgeAttributesWithSizes([2, 2, 3], stride: self.noiseVertices.stride)
        
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.noiseVertices.count))
        
        glActiveTexture(GLenum(GL_TEXTURE0))
        self.noiseProgram.disable()
        self.framebufferStack?.popFramebuffer()
        
        self.bufferIsDirty = false
    }
    
    open func shadeTextureChanged() {
        if let nt = self.shadeTexture {
            let bl = nt.frame.bottomLeftGL
            let br = nt.frame.bottomRightGL
            let tl = nt.frame.topLeftGL
            let tr = nt.frame.topRightGL
            
            self.noiseVertices.alterVertex(TexturedQuad.VertexName.TopLeft) {
                $0.texture = tl.getGLTuple()
                return
            }
            self.noiseVertices.alterVertex(TexturedQuad.VertexName.BottomLeft) {
                $0.texture = bl.getGLTuple()
                return
            }
            self.noiseVertices.alterVertex(TexturedQuad.VertexName.TopRight) {
                $0.texture = tr.getGLTuple()
                return
            }
            self.noiseVertices.alterVertex(TexturedQuad.VertexName.BottomRight) {
                $0.texture = br.getGLTuple()
                return
            }
        }
    }
    
    open func noiseSizeChanged() {
        
        self.noiseVertices.iterateWithHandler() { index, vertex in
            let curPoint = TexturedQuad.pointForIndex(index)
            let curTex = (curPoint * self.noiseSize).getGLTuple()
            vertex.noiseTexture = (curTex.0, curTex.1, vertex.noiseTexture.2)
            return
        }
        
    }//noise size changed
    
    open override func contentSizeChanged() {
        self.buffer = GLSFrameBuffer(size: self.contentSize)
        self.buffer.framebufferStack = self.framebufferStack
        self.texture = self.buffer.ccTexture
        
        let sizeAsPoint = self.contentSize.getCGPoint()
        self.noiseVertices.iterateWithHandler() { index, vertex in
            let curPoint = TexturedQuad.pointForIndex(index)
            vertex.position = (curPoint * sizeAsPoint).getGLTuple()
        }
        
        super.contentSizeChanged()
    }
    
    open func performFadeWithDuration(_ duration:CGFloat, appearing:Bool, completion:(()->())?) {
        let fadeAnimation = NoiseFadeAnimation(sprite: self, duration: duration, appearing: appearing)
        if let completion = completion {
            fadeAnimation.completionHandler = completion
        }
        self.fadeAnimation = fadeAnimation
    }
    
}
