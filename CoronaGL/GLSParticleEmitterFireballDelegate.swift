//
//  GLSParticleEmitterFireballDelegate.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 8/18/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

///A particle emitter that generates a fireball effect. Spawns particles
///radially and additively applies a negative value to their x-direction
///to create the fireball's tail. Set the parent GLSParticleEmitter object's
///anchor to spawnAnchor to position the fireball at the point particles
///are emitted.
open class GLSParticleEmitterFireballDelegate: GLSParticleEmitterDelegate {
    
    open var emitterSize: CGSize {
        let height = self.velocity * self.life + self.size * 2.0
        let width = height + self.tailVelocity * self.life
        return CGSize(width: width, height: height)
    }
    open var maxLife: CGFloat {
        return self.life
    }
    open var spawnAnchor:CGPoint {
        let x = (self.tailVelocity * self.life + self.emitterSize.height / 2.0) / self.emitterSize.width
        return CGPoint(x: x, y: 0.5)
    }
    
    ///The color of the particles.
    open var color:SCVector3 {
        didSet {
            self.add3Animation(oldValue, end: self.color) { [unowned self] in self.color = $0 }
        }
    }
    ///The speed of the particles (emitted radially about the spawn anchor).
    open var velocity:CGFloat {
        didSet {
            self.add1Animation(oldValue, end: self.velocity) { [unowned self] in self.velocity = $0 }
        }
    }
    ///The speed of the particles. This is subtracted from the particles'
    ///x-velocity to create the tail of the fireball.
    open var tailVelocity:CGFloat {
        didSet {
            self.add1Animation(oldValue, end: self.tailVelocity) { [unowned self] in self.tailVelocity = $0 }
        }
    }
    ///How long (in seconds) the particles last.
    open var life:CGFloat {
        didSet {
            self.add1Animation(oldValue, end: self.life) { [unowned self] in self.life = $0 }
        }
    }
    ///The size of the particles.
    open var size:CGFloat {
        didSet {
            self.add1Animation(oldValue, end: self.size) { [unowned self] in self.size = $0 }
        }
    }
    
    ///Animations used by GLSAnimatable. Default implementation
    ///handles updating animations.
    open var animations:[GLSAnimator] = []
    
    ///Initializes a GLSParticleEmitterFireballDelegate.
    public init(color:SCVector3, velocity:CGFloat, tailVelocity:CGFloat, life:CGFloat, size:CGFloat) {
        self.color = color
        self.velocity = velocity
        self.tailVelocity = tailVelocity
        self.life = life
        self.size = size
    }
    
    ///Emits a particle starting at spawn point and moving radially
    ///and in the negative x-direction according to tailVelocity.
    open func emit() -> PEVertex {
        var vertex = PEVertex()
        let velocity = CGPoint(angle: CGFloat.randomAngle(), length: self.velocity) - CGPoint(x: self.tailVelocity)
        vertex.velocity = GLPoint(point: velocity)
        vertex.color = GLVector3(vector: self.color)
        vertex.life = GLfloat(self.life)
        vertex.size = GLfloat(self.size)
        return vertex
    }
    
}
