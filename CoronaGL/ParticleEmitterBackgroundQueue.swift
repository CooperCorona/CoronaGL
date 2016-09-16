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


open class ParticleEmitterBackgroundQueue: NSObject {
   
    open class EReference {
        weak var emitter:GLSParticleEmitter? = nil
        let index:Int
        
        public init(emitter:GLSParticleEmitter, index:Int) {
            
            self.emitter = emitter
            self.index = index
            
        }//initialize
        
        func update(_ dt:CGFloat) {
            
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
    open var references:[EReference] = []
    open let queues = [ DispatchQueue(label: "Particle Emitter Queue 1", attributes: DispatchQueue.Attributes.concurrent) ]
//    let queues = [ dispatch_get_main_queue() ]
    
    /** Used to calculate delta time for updating. Set 'currentDate' to nil to reset timing (could be useful if you pause the update for a while. DT would include all the time while it was paused!) */
    open var currentDate:Date? = nil
    
    static let sharedInstance = ParticleEmitterBackgroundQueue()
    
    open func findMinimumQueue() -> Int {
        
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
    
    open func addEmitter(_ emitter:GLSParticleEmitter) {
    
        let index = self.findMinimumQueue()
        
        self.references.append(EReference(emitter: emitter, index: index))
        
    }//add emitter
    
    open func removeEmitter(_ emitter:GLSParticleEmitter) {
        
        self.references = self.references.filter() { (reference:EReference) in
            reference.emitter !== emitter
        }
        
    }//remove emitter
    
    open func update(_ dt:CGFloat) {
        
        let curDate = Date()
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
    
    open func removeAll() {
        self.references.removeAll(keepingCapacity: true)
    }//remove all
}

public extension ParticleEmitterBackgroundQueue {
    
    public class func addEmitter(_ emitter:GLSParticleEmitter) {
        ParticleEmitterBackgroundQueue.sharedInstance.addEmitter(emitter)
    }
    
    public class func removeEmitter(_ emitter:GLSParticleEmitter) {
        ParticleEmitterBackgroundQueue.sharedInstance.removeEmitter(emitter)
    }
    
    public class func update(_ dt:CGFloat) {
        ParticleEmitterBackgroundQueue.sharedInstance.update(dt)
    }
    
    public class func removeAll() {
        ParticleEmitterBackgroundQueue.sharedInstance.removeAll()
    }
    
}
