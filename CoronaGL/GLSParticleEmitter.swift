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
    
    public var position:(GLfloat, GLfloat) = (0.0, 0.0)
    public var color:(GLfloat, GLfloat, GLfloat) = (0.0, 0.0, 0.0)
    public var size:GLfloat = 0.0
    public var textureAnchor:(GLfloat, GLfloat, GLfloat, GLfloat) = (0.0, 0.0, 1.0, 1.0)
    
    public var description:String {
        return "P-\(position) C-\(color) S-\(size)"
    }
}

public class GLSParticleEmitter: GLSNode, DoubleBuffered {
    
    // MARK: - Types
    
    public class PEVertexData {
        let velocity:CGPoint
        var life:CGFloat
        var isFinished:Bool { return self.life <= 0.0 }
        
        public init(velocity:CGFloat, angle:CGFloat, life:CGFloat) {
            self.velocity = CGPoint(angle: angle, length: velocity)
            self.life = life
        }//initialize
        
        func update(dt:CGFloat, inout vertex:PEVertex) {
            
            self.life -= dt
            
            let pos = CGPoint(tupleGL: vertex.position) + self.velocity * dt
            vertex.position = pos.getGLTuple()
            
        }//update vertex
    }
    
    public class ParticleProgram: GLProgramDictionary {
        
        public init() {
            let program = ShaderHelper.programForString("Universal Particle Shader")!
            let locations = [
                "u_Projection",
                "u_TextureInfo",
                "a_Position",
                "a_Color",
                "a_Size",
                "a_TextureAnchor"
            ]
            super.init(program: program, locations: locations)
        }
        
    }
    
    // MARK: - Properties
    
    public var particles:[PEVertex] = []
    public var particleData:[PEVertexData] = []
    
    public let particleSize:CGFloat
    public let particleSizeRange:CGFloat
    public let particleColor:SCVector3
    public let particleColorRange:SCVector3
    public let particleVelocity:CGFloat
    public let particleVelocityRange:CGFloat
    public let particleLife:CGFloat
    public let particleLifeRange:CGFloat
    public let particleBirthFrequency:CGFloat
    public let particleBirthRate:Int
    public var particleAngleMinimum:CGFloat = 0.0
    public var particleAngleMaximum:CGFloat = 2.0 * CGFloat(M_PI)
    public let particleTexture:CCTexture?
    public let particleTextureAnchor:(GLfloat, GLfloat, GLfloat, GLfloat)
    public var particleSpawnShape:RandomPointProtocol? = nil
    
    public let screenScale:CGFloat = GLSFrameBuffer.getRetinaScale()
    
    public let duration:CGFloat?
    private var durCount:CGFloat = 0.0
    private var spawnCount:CGFloat = 0.0
    
    public var isEmitting = true
    public var smoothEnding = true
    public var removeAutomatically = true
    public var paused = false
    public var updateInBackground = true
    
    public let bufferSize:CGFloat
    public let buffer:GLSFrameBuffer
    
    public let particleProgram = ParticleProgram()
    
    public private(set) var bufferIsDirty = false
    ///CURRENTLY DOES NOTHING. Other GLSNode subclasses invoke renderToTexture in update method if this is true.
    public var shouldRedraw = false
    
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
            let x = GLfloat(tex.frame.origin.x)
            let y = GLfloat(tex.frame.origin.y)
            let w = GLfloat(tex.frame.size.width)
            let h = GLfloat(tex.frame.size.height)
            self.particleTextureAnchor = (x, y, w, h)
        } else {
            self.particleTextureAnchor = (0.0, 0.0, 1.0, 1.0)
        }
        
        self.duration = duration
        self.durCount = self.duration ?? 0.0
        
        var bSize = self.particleVelocity + self.particleVelocityRange / 2.0
        bSize *= (self.particleLife + self.particleLifeRange / 2.0) * 2.0
        bSize += self.particleSize + self.particleSizeRange / 2.0
        self.bufferSize = bSize
        
        let bufSize = CGSize(square: self.bufferSize)
        self.buffer = GLSFrameBuffer(size: bufSize)
        //        self.buffer.clearColor = SCVector4.darkBlueColor
        
        super.init(position: CGPoint.zero, size: bufSize)
        
        self.framebufferStack?.pushGLSFramebuffer(self.buffer)
        self.buffer.bindClearColor()
        self.framebufferStack?.popFramebuffer()
        
        self.vertices = self.buffer.sprite.vertices
        self.texture = self.buffer.sprite.texture
        
//        ParticleEmitterBackgroundQueue.addEmitter(self)
    }//initialize
    
    // MARK: - Logic
    
    public func generateParticle() -> (PEVertex, PEVertexData) {
        
        let color = GLSParticleEmitter.randomVector3(self.particleColor, withRange: self.particleColorRange)
        
        let velocity = GLSParticleEmitter.randomFloat(self.particleVelocity, withRange: self.particleVelocityRange)
        let angle = GLSParticleEmitter.randomFloat(self.particleAngleMinimum, between: self.particleAngleMaximum)
        let life = GLSParticleEmitter.randomFloat(self.particleLife, withRange: self.particleLifeRange)
        let size = GLSParticleEmitter.randomFloat(self.particleSize, withRange: self.particleSizeRange)
        
        var part = PEVertex()
        part.position = self.randomPointForParticle().getGLTuple()
        part.color = color.getGLTuple()
        part.size = GLfloat(size * self.screenScale)
        part.textureAnchor = self.particleTextureAnchor
        
        let data = PEVertexData(velocity: velocity, angle: angle, life: life)
        
        return (part, data)
    }//generate vertex
    
    public func randomPointForParticle() -> CGPoint {
        
        let pCenter = CGPoint(x: bufferSize / 2.0, y: bufferSize / 2.0)
        
        if let spawnShape = self.particleSpawnShape {
            return pCenter + spawnShape.randomPoint()
        }
        
        return pCenter
    }//random point for particle
    
    public override func update(dt: CGFloat) {
        super.update(dt)
        
        self.updateParticles(dt)
        self.updateDuration(dt)
    }
    
    public func updateParticles(dt:CGFloat) {
        
        var storedData      = self.particleData
        var storedParticles = self.particles
        
        var filteredParticles:[PEVertex] = []
        var filteredData:[PEVertexData] = []
        for iii in 0..<storedParticles.count {
            storedData[iii].update(dt, vertex: &storedParticles[iii])
            
            if !storedData[iii].isFinished {
                filteredParticles.append(storedParticles[iii])
                filteredData.append(storedData[iii])
            }
        }
        
        if self.isEmitting {
            let partsToAdd = self.addParticles(dt)
            filteredParticles += partsToAdd.vertices
            filteredData += partsToAdd.data
        }
        
        self.particles = filteredParticles
        self.particleData = filteredData
        
        self.bufferIsDirty = true
    }
    /*
    public func updateParticles(dt:CGFloat) -> (particles:[PEVertex], data:[PEVertexData]) {
        
        var storedData = self.particleData
        var storedParticles = self.particles
        
        for iii in 0..<storedParticles.count {
            
            if (iii >= storedData.count) {
                break
            }
            
            storedData[iii].update(dt, vertex: &storedParticles[iii])
            
        }//update vertices
        
        var filteredParticles:[PEVertex] = []
        for iii in 0..<storedParticles.count {
            
            if (iii >= storedData.count) {
                break
            }
            
            if (!storedData[iii].isFinished) {
                filteredParticles.append(storedParticles[iii])
            }
        }
        storedParticles/*self.particles*/ = filteredParticles
        storedData/*self.particleData*/ = storedData.filter() { !$0.isFinished }
        
        self.updateDuration(dt)
        
        if (self.isEmitting) {
            //            self.addParticles(dt)
            let partsToAdd = self.addParticles(dt)
            storedParticles/*self.particles*/ += partsToAdd.vertices
            storedData/*self.particleData*/ += partsToAdd.data
        }
        
        return (storedParticles, storedData)
    }//potentially add particles
    */
    public func addParticles(dt:CGFloat) -> (vertices:[PEVertex], data:[PEVertexData]) {
        
        self.spawnCount += dt
        var parts:[PEVertex] = []
        var datas:[PEVertexData] = []
        while (self.spawnCount >= self.particleBirthFrequency) {
            
            let (particle, data) = self.generateParticle()
            
//            self.particles.append(particle)
//            self.particleData.append(data)
            parts.append(particle)
            datas.append(data)
            
            self.spawnCount -= self.particleBirthFrequency
        }//spawn a particle
        
        //        return parts
        return (parts, datas)
    }//add particles

    public func updateDuration(dt:CGFloat) {
        
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
    
    
    public func renderToTexture() {
        self.framebufferStack?.pushGLSFramebuffer(self.buffer)
        self.buffer.bindClearColor()
        
        glBlendColor(0, 0, 0, 1.0);
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_CONSTANT_ALPHA));
        
        glUseProgram(self.particleProgram.program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.particleProgram.vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), sizeof(PEVertex) * self.particles.count, self.particles, GLenum(GL_STATIC_DRAW))
        
        let proj = self.projection
        glUniformMatrix4fv(self.particleProgram["u_Projection"], 1, 0, proj.values)
        
        if let tex = self.particleTexture {
            glBindTexture(GLenum(GL_TEXTURE_2D), tex.name)
            glUniform1i(self.particleProgram["u_TextureInfo"], 0)
            /*
            let x = GLfloat(tex.frame.origin.x)
            let y = GLfloat(tex.frame.origin.y)
            let z = GLfloat(tex.frame.size.width)
            let w = GLfloat(tex.frame.size.height)
            glUniform4f(self.particleProgram["u_TextureAnchor"], x, y, z, w)
            */
        }
        
        self.particleProgram.enableAttributes()
        self.particleProgram.bridgeAttributesWithSizes([2, 3, 1, 4], stride: sizeof(PEVertex))
        
        glDrawArrays(GLenum(GL_POINTS), 0, GLsizei(self.particles.count))
        
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        self.particleProgram.disableAttributes()
        self.framebufferStack?.popFramebuffer()
    }
    
    
    deinit {
        ParticleEmitterBackgroundQueue.removeEmitter(self)
    }//deinitialize
    
    
    
    public class var backgroundQueue:dispatch_queue_t {
        struct StaticInstance {
            static var instance:dispatch_queue_t! = nil
            static var onceToken:dispatch_once_t = 0
        }
        dispatch_once(&StaticInstance.onceToken) {
            StaticInstance.instance = dispatch_queue_create("GLSParticleEmitter Update", DISPATCH_QUEUE_SERIAL)
        }
        
        return StaticInstance.instance
    }
    
}

//Get Random Floats/Vectors
public extension GLSParticleEmitter {
    
    
    //Float is in range [0.0, 1.0]
    public class func randomFloat() -> CGFloat {
        let randomInt = Int(arc4random() % 100001)
        return CGFloat(randomInt) / 100000.0
    }
    
    public class func randomFloat(lower:CGFloat, between upper:CGFloat) -> CGFloat {
        
        let factor = GLSParticleEmitter.randomFloat()
        
        return lower + (upper - lower) * factor
    }//get a random float between two values
    
    public class func randomFloat(middle:CGFloat, withRange range:CGFloat) -> CGFloat {
        
        return GLSParticleEmitter.randomFloat(middle - range / 2.0, between: middle + range / 2.0)
        
    }//random float with range
    
    //Values are in range [0.0, 1.0]
    public class func randomVector3() -> SCVector3 {
        
        let x = GLSParticleEmitter.randomFloat()
        let y = GLSParticleEmitter.randomFloat()
        let z = GLSParticleEmitter.randomFloat()
        
        return SCVector3(xValue: x, yValue: y, zValue: z)
        
    }//get a random vector 3 with range
    
    public class func randomVector3(lower:SCVector3, between upper:SCVector3) -> SCVector3 {
        
        let factor = GLSParticleEmitter.randomVector3()
        
        return lower + (upper - lower) * factor
    }//get a random vector 3 between two values
    
    public class func randomVector3(middle:SCVector3, withRange range:SCVector3) -> SCVector3 {
        
        return GLSParticleEmitter.randomVector3(middle - range / 2.0, between: middle + range / 2.0)
        
    }//get a random vector 3 with range
    
}//Random Methods