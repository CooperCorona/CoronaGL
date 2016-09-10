//
//  ParticleEmitterBackgroundQueue.swift
//  Gravity
//
//  Created by Cooper Knaak on 2/23/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif


public class ParticleEmitterBackgroundQueue: NSObject {
   
    public class EReference {
        weak var emitter:GLSParticleEmitter? = nil
        let index:Int
        
        public init(emitter:GLSParticleEmitter, index:Int) {
            
            self.emitter = emitter
            self.index = index
            
        }//initialize
        
        func update(dt:CGFloat) {
            
            self.emitter?.updateParticles(dt)
            
        }//update
        
    }
    /*
    public let queues = [  dispatch_queue_create("Particle Emitter Queue 1", DISPATCH_QUEUE_CONCURRENT),
                    dispatch_queue_create("Particle Emitter Queue 2", DISPATCH_QUEUE_CONCURRENT),
                    dispatch_queue_create("Particle Emitter Queue 3", DISPATCH_QUEUE_CONCURRENT),
                    dispatch_queue_create("Particle Emitter Queue 4", DISPATCH_QUEUE_CONCURRENT)]
    public var queueCounts = [0, 0, 0, 0]
    */
    public var references:[EReference] = []
    public let queues = [ dispatch_queue_create("Particle Emitter Queue 1", DISPATCH_QUEUE_CONCURRENT) ]
//    let queues = [ dispatch_get_main_queue() ]
    
    /** Used to calculate delta time for updating. Set 'currentDate' to nil to reset timing (could be useful if you pause the update for a while. DT would include all the time while it was paused!) */
    public var currentDate:NSDate? = nil
    
    public func findMinimumQueue() -> Int {
        
        return 0
        /*
        var currentIndex = 0
        for iii in 1..<self.queueCounts.count {
            
            if (self.queueCounts[iii] < self.queueCounts[currentIndex]) {
                currentIndex = iii
            }
            
        }
        
        return currentIndex
        */
    }//find queue with minimum number of emitters
    
    public func addEmitter(emitter:GLSParticleEmitter) {
    
        let index = self.findMinimumQueue()
        
        self.references.append(EReference(emitter: emitter, index: index))
        
    }//add emitter
    
    public func removeEmitter(emitter:GLSParticleEmitter) {
        
        self.references = self.references.filter() { (reference:EReference) in
            reference.emitter !== emitter
        }
        
    }//remove emitter
    
    public func update(dt:CGFloat) {
        
        let curDate = NSDate()
//        let deltaTime = CGFloat(curDate.timeIntervalSinceDate(self.currentDate ?? NSDate()))
        self.currentDate = curDate
        /*
        dispatch_async(self.queues[0]) {
        
        for cur in self.references {
            /*
//            dispatch_async(self.queues[cur.index]) {
                if let pData = cur.emitter?.updateParticles(deltaTime) {
//                    dispatch_async(dispatch_get_main_queue()) {
//                    dispatch_async(GLSUniversalRenderer.sharedInstance.backgroundQueue) {
                        cur.emitter?.particles = pData.particles
                        cur.emitter?.particleData = pData.data
//                    }
                }
             */
            }

        }
        */
    }//update
    
    public func removeAll() {
        self.references.removeAll(keepCapacity: true)
    }//remove all
}

public extension ParticleEmitterBackgroundQueue {
    
    public class var sharedInstance:ParticleEmitterBackgroundQueue {
        struct StaticInstance {
            static var instance:ParticleEmitterBackgroundQueue! = nil
            static var onceToken:dispatch_once_t = 0
        }
        
        dispatch_once(&StaticInstance.onceToken) {
            StaticInstance.instance = ParticleEmitterBackgroundQueue()
        }
        
        return StaticInstance.instance
    }
    
    public class func addEmitter(emitter:GLSParticleEmitter) {
        ParticleEmitterBackgroundQueue.sharedInstance.addEmitter(emitter)
    }
    
    public class func removeEmitter(emitter:GLSParticleEmitter) {
        ParticleEmitterBackgroundQueue.sharedInstance.removeEmitter(emitter)
    }
    
    public class func update(dt:CGFloat) {
        ParticleEmitterBackgroundQueue.sharedInstance.update(dt)
    }
    
    public class func removeAll() {
        ParticleEmitterBackgroundQueue.sharedInstance.removeAll()
    }
    
}