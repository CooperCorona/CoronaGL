//
//  GLSParticleLayer.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/27/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import CoronaConvenience
import CoronaStructures


public struct GLSParticle {
    public var position:(GLfloat, GLfloat) = (0.0, 0.0)
    public var color:(GLfloat, GLfloat, GLfloat, GLfloat) = (0.0, 0.0, 0.0, 0.0)
    public var size:GLfloat = 0.0
    
    //These properties are not used by the shader.
    public var velocity:(GLfloat, GLfloat) = (0.0, 0.0)
    public var life:GLfloat = 0.0
    ///Do not set directly. GLSParticleLayer uses this internally.
    public var emitterId:GLint = -1
    
    init(position:(GLfloat, GLfloat), life:GLfloat, color:(GLfloat, GLfloat, GLfloat, GLfloat), velocity:(GLfloat, GLfloat), size:GLfloat) {
        self.position = position
        self.life = life
        self.color = color
        self.velocity = velocity
        self.size = size
        self.emitterId = -1
    }
}

public protocol GLSParticleLayerEmitter {
    
    var particlesToSpawn:Int { get }
    var isFinished:Bool { get }
    mutating func update(dt:CGFloat)
    mutating func emit() -> GLSParticle
    
}

public struct GLSDefaultParticleLayerEmitter: GLSParticleLayerEmitter {
    
    public var position:CGPoint
    public var life:CGFloat
    public var color:SCVector4
    public var velocity:CGFloat
    public var size:CGFloat
    public var rate:CGFloat
    public var time:CGFloat = 0.0
    public var duration:CGFloat?
    
    public init(position: CGPoint, life: CGFloat, color: SCVector4, velocity: CGFloat, size:CGFloat, rate: CGFloat, duration:CGFloat?) {
        self.position = position
        self.life = life
        self.color = color
        self.velocity = velocity
        self.size = size
        self.rate = rate
        self.duration = duration
    }
    
    public var isFinished: Bool {
        if let duration = self.duration {
            return self.time >= duration
        } else {
            return false
        }
    }
    public var particlesToSpawn: Int {
        return Int(self.rate * self.time)
    }
    
    public mutating func update(dt: CGFloat) {
        self.time += dt
    }
    
    public mutating func emit() -> GLSParticle {
        self.time -= 1.0 / self.rate
        let velocity = CGPoint(angle: CGFloat.randomMiddle(0.0, range: 2.0 * CGFloat.pi), length: self.velocity)
        return GLSParticle(position: self.position.getGLTuple(), life: GLfloat(self.life), color: self.color.getGLTuple(), velocity: velocity.getGLTuple(), size: GLfloat(size))
    }
}

public class GLSDefaultParticleLayerEmitterNode: GLSNode, GLSParticleLayerEmitter {
    
    private var underlyingEmitter:GLSParticleLayerEmitter
    public var particlesToSpawn: Int { return self.underlyingEmitter.particlesToSpawn }
    public var isFinished: Bool { return self.underlyingEmitter.isFinished }
    
    public init(emitter:GLSParticleLayerEmitter) {
        self.underlyingEmitter = emitter
        super.init(position: CGPoint.zero, size: CGSize.zero)
    }
    
    public func update(dt: CGFloat) {
        self.underlyingEmitter.update(dt: dt)
    }
    
    public func emit() -> GLSParticle {
        var particle = self.underlyingEmitter.emit()
        particle.position = (self.recursiveModelMatrix() * CGPoint(tupleGL: particle.position)).getGLTuple()
        return particle
    }
    
}

/**
 Defines a framebuffer that renders particles. Previous implementations
 of particle emitters were separate sprites that used their own
 framebuffers. This defines a single framebuffer (presumably the size
 of the screen) that renders *all* particle emitters to the same
 framebuffer. This will allow interactions, hopefully speed up the
 rendering, and be an opportunity to update the emitter logic. It also
 allows particles to move independently of their emitters / other particles
 once spawned.
 */
open class GLSParticleLayer: GLSSprite, DoubleBuffered {

    // MARK: - Types
    
    /**
     Because GLSParticleLayerEmitter is a protocol, implementing
     type can be structs. We still want a way to identify each one
     uniquely, so we use an integer id and return this tuple after
     adding the emitter so callers can remove their emitters if necessary.
     */
    public struct EmitterTuple {
        public var id:GLint
        public var emitter:GLSParticleLayerEmitter
    }
    
    // MARK: - Properties
    
    ///Extra space added to each edge of the framebuffer
    ///so particles don't vanish when their underlying
    ///points go offscreen. Any particles *larger* than
    ///this value will still exhibit the vanishing effect.
    public static let PARTICLE_SIZE_BUFFER:CGFloat = 32.0
    private let particleProgram = ShaderHelper.programDictionaryForString("Particle Layer Shader")!
    private var emitters:[GLint:GLSParticleLayerEmitter] = [:]
    private var particles:[GLSParticle] = []
    private var currentId:GLint = 0
    public var particleTexture:CCTexture? = nil
    public var additiveBlending = true
    
    private(set) public var buffer: GLSFrameBuffer
    public var bufferIsDirty = false
    public var shouldRedraw = false
    
    // MARK: - Setup
    
    public static func bufferSize(for size:CGSize) -> CGSize {
        return size + 2.0 * GLSParticleLayer.PARTICLE_SIZE_BUFFER
    }
    
    private static func getCCTexture(from buffer:GLSFrameBuffer) -> CCTexture {
        let xInset = GLSParticleLayer.PARTICLE_SIZE_BUFFER / buffer.contentSize.width
        let yInset = GLSParticleLayer.PARTICLE_SIZE_BUFFER / buffer.contentSize.height
        return CCTexture(name: buffer.ccTexture.name, frame: buffer.ccTexture.frame.insetBy(dx: xInset, dy: yInset))
    }
    
    public init(size:CGSize, texture:CCTexture?) {
        self.buffer = GLSFrameBuffer(size: GLSParticleLayer.bufferSize(for: size))
        self.particleTexture = texture
        super.init(position: size.center, size: size, texture: GLSParticleLayer.getCCTexture(from: self.buffer))
    }
    
    open override func contentSizeChanged() {
        self.buffer = GLSFrameBuffer(size: GLSParticleLayer.bufferSize(for: self.contentSize))
        self.texture = GLSParticleLayer.getCCTexture(from: self.buffer)
        super.contentSizeChanged()
        
        self.bufferIsDirty = true
    }
    
    // MARK: - Logic
    
    private func getId() -> GLint {
        //If the id ever overflows (after a quintillion ids),
        //we just reset. It's virtually impossible to have some
        //sort of collision with a quintillion ids, so we just
        //increment and assign rather than trying to force uniqueness.
        self.currentId = self.currentId &+ 1
        return self.currentId
    }
    
    @discardableResult public func add(emitter:GLSParticleLayerEmitter) -> EmitterTuple {
        let tuple = EmitterTuple(id: self.getId(), emitter: emitter)
        self.emitters[tuple.id] = tuple.emitter
        return tuple
    }
    
    @discardableResult public func remove(emitterWith id:GLint) -> EmitterTuple? {
        if let emitter = self.emitters[id] {
            self.emitters[id] = nil
            self.particles = self.particles.filter() { $0.emitterId != id }
            return EmitterTuple(id: id, emitter: emitter)
        } else {
            return nil
        }
    }
    
    @discardableResult public func remove(emitter:EmitterTuple) -> EmitterTuple? {
        return self.remove(emitterWith: emitter.id)
    }
    
    open override func update(_ dt: CGFloat) {
        super.update(dt)
        self.updateEmitters(dt: dt)
    }
    
    open func updateEmitters(dt:CGFloat) {
        var idsToRemove = Set<GLint>()
        
        for id in self.emitters.keys {
            self.emitters[id]!.update(dt: dt)
            while self.emitters[id]!.particlesToSpawn > 0 {
                var particle = self.emitters[id]!.emit()
                //Offset because we have an inset on the sides
                //of the framebuffer.
                //TODO: This offset needs to be based on the anchor or something.
                //Clicked in the middle works fine, but clicked to the left
                //offsets the spawn more to the left (relatively) than desired, for example.
                particle.position = (particle.position.0 + GLfloat(GLSParticleLayer.PARTICLE_SIZE_BUFFER), particle.position.1 + GLfloat(GLSParticleLayer.PARTICLE_SIZE_BUFFER))
                particle.emitterId = id
                self.particles.append(particle)
                self.bufferIsDirty = true
            }
            if self.emitters[id]!.isFinished {
                idsToRemove.insert(id)
            }
        }
        for i in 0..<self.particles.count {
            self.particles[i].life -= GLfloat(dt)
            self.particles[i].position = (self.particles[i].position.0 + GLfloat(dt) * self.particles[i].velocity.0, self.particles[i].position.1 + GLfloat(dt) * self.particles[i].velocity.1)
        }
        
        self.particles = self.particles.filter() { !idsToRemove.contains($0.emitterId) && $0.life > 0.0 }
        for id in idsToRemove {
            self.emitters[id] = nil
        }
        
        if idsToRemove.count > 0 {
            self.bufferIsDirty = true
        }
    }
    
    public func renderToTexture() {
        let result = self.framebufferStack?.pushGLSFramebuffer(buffer: self.buffer)
        if result != true {
            print("Error (GLSParticleLayerEmitter): framebuffer failed to push (\(result)).")
        }
        
#if os(OSX)
        glEnable(GLenum(GL_VERTEX_PROGRAM_POINT_SIZE))
        glEnable(GLenum(GL_PROGRAM_POINT_SIZE))
#endif
        
        self.buffer.bindClearColor()
        
        if self.additiveBlending {
            glBlendColor(0, 0, 0, 1.0);
            glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_CONSTANT_ALPHA));
        }
        
        self.particleProgram.use()
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLSParticle>.size * self.particles.count, self.particles, GLenum(GL_STATIC_DRAW))
        
        self.particleProgram.uniformMatrix4fv("u_Projection", matrix: self.projection)
        
        if let tex = self.particleTexture {
            glBindTexture(GLenum(GL_TEXTURE_2D), tex.name)
            glUniform1i(self.particleProgram["u_TextureInfo"], 0)
            self.particleProgram.uniform4f("u_TextureAnchor", value: SCVector4(x: tex.frame.origin.x, y: tex.frame.origin.y, z: tex.frame.size.width, w: tex.frame.size.height))
        }
        self.particleProgram.enableAttributes()
        self.particleProgram.bridgeAttributesWithSizes([2, 4, 1], stride: MemoryLayout<GLSParticle>.size)
        glDrawArrays(GLenum(GL_POINTS), 0, GLsizei(self.particles.count))
        
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        
        self.particleProgram.disable()
        self.framebufferStack?.popFramebuffer()
        self.bufferIsDirty = false
    }
    
}
