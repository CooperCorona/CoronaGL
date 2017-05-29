//
//  GLSParticleEmitter.swift
//  Gravity
//
//  Created by Cooper Knaak on 2/19/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

//Conform to random point protocol to let
//'GLSParticleEmitter' use your class
//to spawn particles in random positions
public protocol RandomPointProtocol {
    func randomPoint() -> CGPoint
}

public struct PEVertex: CustomStringConvertible {
    
    public var position:GLPoint = GLPoint(x: 0.0, y: 0.0)
    public var color = GLVector3()
    public var size:GLfloat = 0.0
    public var textureAnchor = GLVector4(x: 0.0, y: 0.0, z: 1.0, w: 1.0)
    
    public var velocity:GLPoint = GLPoint()
    public var life:GLfloat = 0.0
    public var isFinished:Bool { return self.life <= 0.0 }
    
    mutating public func update(_ dt:CGFloat) {
        self.life -= GLfloat(dt)
        self.position += self.velocity * dt
    }//update vertex
    
    public var description:String {
        return "P-\(position) C-\(color) S-\(size)"
    }
}

open class GLSParticleEmitter: GLSSprite, DoubleBuffered {
    
    // MARK: - Properties
    
    open var particles:[PEVertex] = []
    
    open let particleSize:CGFloat
    open let particleSizeRange:CGFloat
    open let particleColor:SCVector3
    open let particleColorRange:SCVector3
    open let particleVelocity:CGFloat
    open let particleVelocityRange:CGFloat
    open let particleLife:CGFloat
    open let particleLifeRange:CGFloat
    open let particleBirthFrequency:CGFloat
    open let particleBirthRate:Int
    open var particleAngleMinimum:CGFloat = 0.0
    open var particleAngleMaximum:CGFloat = 2.0 * CGFloat.pi
    open let particleTexture:CCTexture?
    open let particleTextureAnchor:GLVector4
    open var particleSpawnShape:RandomPointProtocol? = nil
    
    open let screenScale:CGFloat = GLSFrameBuffer.getRetinaScale()
    
    open let duration:CGFloat?
    fileprivate var durCount:CGFloat = 0.0
    fileprivate var spawnCount:CGFloat = 0.0
    
    open var isEmitting = true
    open var smoothEnding = true
    open var removeAutomatically = true
    open var paused = false
    open var updateInBackground = true
    
    open let bufferSize:CGFloat
    open let buffer:GLSFrameBuffer
    
    open let particleProgram = ShaderHelper.programDictionaryForString("Universal Particle Shader")!
//    open let particleProgram = ShaderHelper.programDictionaryForString("Test Particles")!
    
    open fileprivate(set) var bufferIsDirty = false
    ///CURRENTLY DOES NOTHING. Other GLSNode subclasses invoke renderToTexture in update method if this is true.
    open var shouldRedraw = false
    
    // MARK: - Setup

    public init(size:CGFloat, color:SCVector3, velocity:CGFloat, life:CGFloat, birth:Int, duration:CGFloat?, texture:CCTexture?, sizeRange:CGFloat = 0.0, colorRange: SCVector3 = SCVector3(), velocityRange:CGFloat = 0.0, lifeRange:CGFloat = 0.0) {
        
        self.particleSize = size
        self.particleSizeRange = sizeRange
        self.particleColor = color
        self.particleColorRange = colorRange
        self.particleVelocity = velocity
        self.particleVelocityRange = velocityRange
        self.particleLife = life
        self.particleLifeRange = lifeRange
        self.particleBirthRate = birth
        self.particleBirthFrequency = 1.0 / CGFloat(birth)
        self.particleTexture = texture
        
        if let tex = self.particleTexture {
            self.particleTextureAnchor = GLVector4(rect: tex.frame)
        } else {
            self.particleTextureAnchor = GLVector4(x: 0.0, y: 0.0, z: 1.0, w: 1.0)
        }
        
        self.duration = duration
        self.durCount = self.duration ?? 0.0
        
        var bSize = self.particleVelocity + self.particleVelocityRange / 2.0
        bSize *= (self.particleLife + self.particleLifeRange / 2.0) * 2.0
        bSize += self.particleSize + self.particleSizeRange / 2.0
        self.bufferSize = bSize
        
        let bufSize = CGSize(square: self.bufferSize)
        self.buffer = GLSFrameBuffer(size: bufSize)
        
        super.init(position: CGPoint.zero, size: bufSize, texture: self.buffer.ccTexture)
    }//initialize
    
    // MARK: - Logic
    
    open func generateParticle() -> PEVertex {
        
        let color = GLSParticleEmitter.randomVector3(self.particleColor, withRange: self.particleColorRange)
        
        let velocity = GLSParticleEmitter.randomFloat(self.particleVelocity, withRange: self.particleVelocityRange)
        let angle = GLSParticleEmitter.randomFloat(self.particleAngleMinimum, between: self.particleAngleMaximum)
        let life = GLSParticleEmitter.randomFloat(self.particleLife, withRange: self.particleLifeRange)
        let size = GLSParticleEmitter.randomFloat(self.particleSize, withRange: self.particleSizeRange)
        
        var part = PEVertex()
        part.position = GLPoint(point: self.randomPointForParticle())
        part.color = color.getGLVector()
        part.size = GLfloat(size * self.screenScale)
        part.textureAnchor = self.particleTextureAnchor
        
        part.velocity = GLPoint(point: CGPoint(angle: angle, length: velocity))
        part.life = GLfloat(life)
        
        return part
    }//generate vertex
    
    open func randomPointForParticle() -> CGPoint {
        
        let pCenter = CGPoint(x: bufferSize / 2.0, y: bufferSize / 2.0)
        
        if let spawnShape = self.particleSpawnShape {
            return pCenter + spawnShape.randomPoint()
        }
        
        return pCenter
    }//random point for particle
    
    open override func update(_ dt: CGFloat) {
        super.update(dt)
        
        self.updateParticles(dt)
        self.updateDuration(dt)
    }
    
    open func updateParticles(_ dt:CGFloat) {
        
        var storedParticles = self.particles
        
        var filteredParticles:[PEVertex] = []
        for i in 0..<storedParticles.count {
            storedParticles[i].update(dt)
            
            if !storedParticles[i].isFinished {
                filteredParticles.append(storedParticles[i])
            }
        }
        
        if self.isEmitting {
            let partsToAdd = self.addParticles(dt)
            filteredParticles += partsToAdd
        }
        
        self.particles = filteredParticles
        
        self.bufferIsDirty = true
    }

    open func addParticles(_ dt:CGFloat) -> [PEVertex] {
        
        self.spawnCount += dt
        var parts:[PEVertex] = []
        while (self.spawnCount >= self.particleBirthFrequency) {
            let particle = self.generateParticle()
            parts.append(particle)
            
            self.spawnCount -= self.particleBirthFrequency
        }//spawn a particle
        
        return parts
    }//add particles

    open func updateDuration(_ dt:CGFloat) {
        
        if let _ = self.duration {
            self.durCount -= dt
            
            if (self.removeAutomatically && self.durCount <= 0.0) {
                self.removeAtUpdate = true
            }
            
            if (self.smoothEnding && self.durCount <= self.particleLife) {
                self.isEmitting = false
            }
            
        }//valid to update duration
        
    }//update duration
    
    open func renderToTexture() {
        self.framebufferStack?.pushGLSFramebuffer(buffer: self.buffer)
        
        glEnable(GLenum(GL_VERTEX_PROGRAM_POINT_SIZE))
        glEnable(GLenum(GL_PROGRAM_POINT_SIZE))
        
        self.buffer.bindClearColor()
        
        glBlendColor(0, 0, 0, 1.0);
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_CONSTANT_ALPHA));
        
        self.particleProgram.use()
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<PEVertex>.size * self.particles.count, self.particles, GLenum(GL_STATIC_DRAW))
        
        self.particleProgram.uniformMatrix4fv("u_Projection", matrix: self.projection)
        
        if let tex = self.particleTexture {
            glBindTexture(GLenum(GL_TEXTURE_2D), tex.name)
            glUniform1i(self.particleProgram["u_TextureInfo"], 0)
        }
 
        self.particleProgram.enableAttributes()
        self.particleProgram.bridgeAttributesWithSizes([2, 3, 1, 4], stride: MemoryLayout<PEVertex>.size)
        glDrawArrays(GLenum(GL_POINTS), 0, GLsizei(self.particles.count))
        
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        
        self.particleProgram.disable()
        self.framebufferStack?.popFramebuffer()
        self.bufferIsDirty = false
    }
    
    
    deinit {
        ParticleEmitterBackgroundQueue.removeEmitter(self)
    }//deinitialize
    
    
    /*
    open class var backgroundQueue:DispatchQueue {
        struct StaticInstance {
            static var instance:DispatchQueue! = nil
            static var onceToken:Int = 0
        }
        _ = GLSParticleEmitter.__once
        
        return StaticInstance.instance
    }
    */
}

//Get Random Floats/Vectors
public extension GLSParticleEmitter {
    
    
    //Float is in range [0.0, 1.0]
    public class func randomFloat() -> CGFloat {
        let randomInt = Int(arc4random() % 100001)
        return CGFloat(randomInt) / 100000.0
    }
    
    public class func randomFloat(_ lower:CGFloat, between upper:CGFloat) -> CGFloat {
        
        let factor = GLSParticleEmitter.randomFloat()
        
        return lower + (upper - lower) * factor
    }//get a random float between two values
    
    public class func randomFloat(_ middle:CGFloat, withRange range:CGFloat) -> CGFloat {
        
        return GLSParticleEmitter.randomFloat(middle - range / 2.0, between: middle + range / 2.0)
        
    }//random float with range
    
    //Values are in range [0.0, 1.0]
    public class func randomVector3() -> SCVector3 {
        
        let x = GLSParticleEmitter.randomFloat()
        let y = GLSParticleEmitter.randomFloat()
        let z = GLSParticleEmitter.randomFloat()
        
        return SCVector3(xValue: x, yValue: y, zValue: z)
        
    }//get a random vector 3 with range
    
    public class func randomVector3(_ lower:SCVector3, between upper:SCVector3) -> SCVector3 {
        
        let factor = GLSParticleEmitter.randomVector3()
        
        return lower + (upper - lower) * factor
    }//get a random vector 3 between two values
    
    public class func randomVector3(_ middle:SCVector3, withRange range:SCVector3) -> SCVector3 {
        
        return GLSParticleEmitter.randomVector3(middle - range / 2.0, between: middle + range / 2.0)
        
    }//get a random vector 3 with range
    
}//Random Methods
