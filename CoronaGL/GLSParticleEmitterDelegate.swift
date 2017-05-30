//
//  GLSParticleEmitterDelegate.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/29/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
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
public protocol GLSParticleEmitterDelegate {
    
    ///Used by the particle emitter to determine how large to make the underlying buffer.
    var emitterSize:CGSize { get }
    ///Used by the particle emitter to stop emitting in time for smooth endings.
    var maxLife:CGFloat { get }
    
    func emit() -> PEVertex
    
}

public struct GLSParticleEmitterDefaultDelegate: GLSParticleEmitterDelegate {
    
    public var emitterSize: CGSize {
        return CGSize(square: self.velocity * self.life + self.size * 2.0)
    }
    public var maxLife:CGFloat {
        return self.life
    }
    
    public var color:SCVector3
    public var velocity:CGFloat
    public var life:CGFloat
    public var size:CGFloat
    
    public init(color:SCVector3, velocity:CGFloat, life:CGFloat, size:CGFloat) {
        self.color = color
        self.velocity = velocity
        self.life = life
        self.size = size
    }
    
    public func emit() -> PEVertex {
        var vertex = PEVertex()
        vertex.position = GLPoint()
        vertex.velocity = GLPoint(point: CGPoint(angle: CGFloat.randomMiddle(0.0, range: 2.0 * CGFloat.pi), length: self.velocity))
        vertex.life = GLfloat(self.life)
        vertex.color = GLVector3(vector: self.color)
        vertex.size = GLfloat(self.size)
        return vertex
    }
    
}

public struct GLSParticleEmitterRandomDelegateWrapper: GLSParticleEmitterDelegate {
    
    public var emitterSize: CGSize {
        let velocityIncrease = (1.0 + self.velocityFactor / 2.0)
        let lifeIncrease = (1.0 + self.lifeFactor / 2.0)
        let sizeIncrease = (1.0 + self.sizeFactor / 2.0)
        return self.wrappedDelegate.emitterSize * velocityIncrease * lifeIncrease * sizeIncrease
    }
    public var maxLife:CGFloat {
        return self.wrappedDelegate.maxLife + self.lifeFactor / 2.0
    }
    
    public let wrappedDelegate:GLSParticleEmitterDelegate
    public var colorFactor:SCVector3
    public var velocityFactor:CGFloat
    public var velocityAngleFactor:CGFloat
    public var lifeFactor:CGFloat
    public var sizeFactor:CGFloat
    
    public init(delegate:GLSParticleEmitterDelegate) {
        self.wrappedDelegate = delegate
        self.colorFactor = SCVector3()
        self.velocityFactor = 0.0
        self.velocityAngleFactor = 0.0
        self.lifeFactor = 0.0
        self.sizeFactor = 0.0
    }
    
    public init(delegate:GLSParticleEmitterDelegate, colorFactor:SCVector3, velocityFactor:CGFloat, velocityAngleFactor:CGFloat, lifeFactor:CGFloat, sizeFactor:CGFloat) {
        self.wrappedDelegate = delegate
        self.colorFactor = colorFactor
        self.velocityFactor = velocityFactor
        self.velocityAngleFactor = velocityAngleFactor
        self.lifeFactor = lifeFactor
        self.sizeFactor = sizeFactor
    }
    
    public func emit() -> PEVertex {
        var vertex = self.wrappedDelegate.emit()
        let r = CGFloat.randomMiddle(1.0, range: self.colorFactor.r)
        let g = CGFloat.randomMiddle(1.0, range: self.colorFactor.g)
        let b = CGFloat.randomMiddle(1.0, range: self.colorFactor.b)
        vertex.color *= SCVector3(x: r, y: g, z: b)
        vertex.size *= GLfloat(CGFloat.randomMiddle(1.0, range: self.sizeFactor))
        vertex.life *= GLfloat(CGFloat.randomMiddle(1.0, range: self.lifeFactor))
        
        let velocity = vertex.velocity.getCGPoint()
        let length = velocity.length() * CGFloat.randomMiddle(1.0, range: self.velocityFactor)
        let angle = velocity.angle() * CGFloat.randomMiddle(1.0, range: self.velocityAngleFactor)
        vertex.velocity = GLPoint(point: CGPoint(angle: angle, length: length))
        
        return vertex
    }
    
}
