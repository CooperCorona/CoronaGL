//
//  TrilinearArray.swift
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
import CoronaConvenience
import CoronaStructures

/**
Wrapper for array of interpolatable type.
Provides convenience properties, subscript,
and methods to get trilinearly interpolated value.
*/
public class TrilinearArray<T: Interpolatable>: CustomStringConvertible {
    
    private var values:[T] = []
    
    ///Contains uniform (0-1) value of vertex at corresponding index.
    public let vertexValues = [
        SCVector3(x: 0.0, y: 0.0, z: 0.0),
        SCVector3(x: 1.0, y: 0.0, z: 0.0),
        SCVector3(x: 0.0, y: 1.0, z: 0.0),
        SCVector3(x: 1.0, y: 1.0, z: 0.0),
        SCVector3(x: 0.0, y: 0.0, z: 1.0),
        SCVector3(x: 1.0, y: 0.0, z: 1.0),
        SCVector3(x: 0.0, y: 1.0, z: 1.0),
        SCVector3(x: 1.0, y: 1.0, z: 1.0)
    ]
    
    ///If true, then interpolation calculates proper midpoint by smoothstep(mid)
    public var shouldSmooth = true
    
    // MARK: - Vertex Properties
    
    ///Index 0
    public var bottomLeftBehind:T {
        get {
            return self.values[0]
        }
        set {
            self.values[0] = newValue
        }
    }
    
    ///Index 1
    public var bottomRightBehind:T {
        get {
            return self.values[1]
        }
        set {
            self.values[1] = newValue
        }
    }
    
    ///Index 2
    public var topLeftBehind:T {
        get {
            return self.values[2]
        }
        set {
            self.values[2] = newValue
        }
    }
    
    ///Index 3
    public var topRightBehind:T {
        get {
            return self.values[3]
        }
        set {
            self.values[3] = newValue
        }
    }
    
    ///Index 4
    public var bottomLeftFront:T {
        get {
            return self.values[4]
        }
        set {
            self.values[4] = newValue
        }
    }
    
    ///Index 5
    public var bottomRightFront:T {
        get {
            return self.values[5]
        }
        set {
            self.values[5] = newValue
        }
    }
    
    ///Index 6
    public var topLeftFront:T {
        get {
            return self.values[6]
        }
        set {
            self.values[6] = newValue
        }
    }
    
    ///Index 7
    public var topRightFront:T {
        get {
            return self.values[7]
        }
        set {
            self.values[7] = newValue
        }
    }
    
    // MARK: - Setup
    
    ///Populates array with 8 copies of supplied value.
    public init(value:T) {
        for _ in 0..<8 {
            self.values.append(value)
        }
    }
    
    public init(populate:(Int, SCVector3) -> T) {
        
        for (iii, vec) in self.vertexValues.enumerate() {
            self.values.append(populate(iii, vec))
        }
        
    }//initialize with handler
    
    // MARK: - Logic
    
    /**
    Uses trilinear interpolation to calculate value.
    
    - parameter mid: 3-component vector with ranges in [0.0, 1.0] determining point to interpolate to.
    - returns: Trilinearly interpolated value.
    */
    public func interpolate(mid:SCVector3) -> T {
        
        let midVec:SCVector3
        if self.shouldSmooth {
            midVec = smoothstep(mid)
        } else {
            midVec = mid
        }
        
        // trilinearlyInterpolate(_, values:) is guarunteed to
        // exist when values.count >= 8, which this class
        // guaruntees, so I can safely force unwrap the optional.
        return trilinearlyInterpolate(midVec, values: self.values)!
        
    }//trilinearly interpolate
    
    /**
    Uses trilinear interpolation to calculate value.
    
    Identical to calling
    interpolate(SCVector3(x: x, y: y, z: z)
    
    - parameter x: X-component with range in [0.0, 1.0] to interpolate to.
    - parameter y: Y-component with range in [0.0, 1.0] to interpolate to.
    - parameter z: Z-component with range in [0.0, 1.0] to interpolate to.
    - returns: Trilinearly interpolated value.
    */
    public func interpolateX(x:CGFloat, y:CGFloat, z:CGFloat) -> T {
        return self.interpolate(SCVector3(x: x, y: y, z: z))
    }
    
    ///Subscripted access to values array.
    public subscript(index:Int) -> T? {
        get {
            if index < 0 || index >= self.values.count {
                return nil
            }
            return self.values[index]
        }
        set {
            if let val = newValue where (index >= 0 && index < self.values.count) {
                self.values[index] = val
            }
        }
    }
    
    
    // MARK: - CustomStringConvertible
    public var description:String { return "\(self.values)" }
    
}
