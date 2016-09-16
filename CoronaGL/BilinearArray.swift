//
//  BilinearArray.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 6/1/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaStructures

open class BilinearArray<T: Interpolatable>: CustomStringConvertible {
    
    fileprivate var values:[T] = []
    
    ///Contains uniform (0-1) value of vertex at corresponding index.
    open let vertexValues = [
        CGPoint(x: 0.0, y: 0.0),
        CGPoint(x: 1.0, y: 0.0),
        CGPoint(x: 0.0, y: 1.0),
        CGPoint(x: 1.0, y: 1.0)
    ]
    
    ///If true, then interpolation calculates proper midpoint by smoothstep(mid)
    open var shouldSmooth = true
    
    // MARK: - Vertex Properties
    
    ///Index 0
    open var bottomLeft:T {
        get {
            return self.values[0]
        }
        set {
            self.values[0] = newValue
        }
    }
    
    ///Index 1
    open var bottomRight:T {
        get {
            return self.values[1]
        }
        set {
            self.values[1] = newValue
        }
    }
    
    ///Index 2
    open var topLeft:T {
        get {
            return self.values[2]
        }
        set {
            self.values[2] = newValue
        }
    }
    
    ///Index 3
    open var topRight:T {
        get {
            return self.values[3]
        }
        set {
            self.values[3] = newValue
        }
    }
    
    // MARK: - Setup
    
    ///Populates array with 4 copies of supplied value.
    public init(value:T) {
        for _ in 0..<4 {
            self.values.append(value)
        }
    }
    
    public init(populate:(Int, CGPoint) -> T) {
        
        for (iii, vec) in self.vertexValues.enumerated() {
            self.values.append(populate(iii, vec))
        }
        
    }//initialize with handler
    
    // MARK: - Logic
    
    /**
    Uses bilinear interpolation to calculate value.
    
    - parameter mid: 2-component vector with ranges in [0.0, 1.0] determining point to interpolate to.
    - returns: Bilinearly interpolated value.
    */
    open func interpolate(_ mid:CGPoint) -> T {
        
        let midVec:CGPoint
        if self.shouldSmooth {
            let x = mid.x * mid.x * (3.0 - 2.0 * mid.x)
            let y = mid.y * mid.y * (3.0 - 2.0 * mid.y)
            midVec = CGPoint(x: x, y: y)
        } else {
            midVec = mid
        }
        
        // bilinearlyInterpolate(_, values:) is guarunteed to
        // exist when values.count >= 4, which this class
        // guaruntees, so I can safely force unwrap the optional.
        return bilinearlyInterpolate(midVec, values: self.values)!
        
    }//trilinearly interpolate
    
    /**
    Uses bilinear interpolation to calculate value.
    
    Identical to calling
    interpolate(CGPoint(x: x, y: y))
    
    - parameter x: X-component with range in [0.0, 1.0] to interpolate to.
    - parameter y: Y-component with range in [0.0, 1.0] to interpolate to.
    - returns: Bilinearly interpolated value.
    */
    open func interpolateX(_ x:CGFloat, y:CGFloat) -> T {
        return self.interpolate(CGPoint(x: x, y: y))
    }
    
    ///Subscripted access to values array.
    open subscript(index:Int) -> T? {
        get {
            if index < 0 || index >= self.values.count {
                return nil
            }
            return self.values[index]
        }
        set {
            if let val = newValue , (index >= 0 && index < self.values.count) {
                self.values[index] = val
            }
        }
    }
    
    
    // MARK: - CustomStringConvertible
    open var description:String { return "\(self.values)" }
    
}
