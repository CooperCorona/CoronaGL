//
//  LinearArray.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 10/13/15.
//  Copyright © 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

public class LinearArray<T: Interpolatable>: CustomStringConvertible {
    
    private var values:[T] = []
    
    ///Contains uniform (0-1) value of vertex at corresponding index.
    public let vertexValues:[CGFloat] = [0.0, 1.0]
    
    ///If true, then interpolation calculates proper midpoint by smoothstep(mid)
    public var shouldSmooth = true
    
    // MARK: - Vertex Properties
    
    ///Index 0
    public var left:T {
        get {
            return self.values[0]
        }
        set {
            self.values[0] = newValue
        }
    }
    public var right:T {
        get {
            return self.values[1]
        }
        set {
            self.values[1] = newValue
        }
    }
    
    // MARK: - Setup
    
    ///Populates array with 2 copies of supplied value.
    public init(value:T) {
        for _ in 0..<2 {
            self.values.append(value)
        }
    }
    
    public init(populate:(Int, CGFloat) -> T) {
        
        for (iii, vec) in self.vertexValues.enumerate() {
            self.values.append(populate(iii, vec))
        }
        
    }//initialize with handler
    
    // MARK: - Logic
    
    /**
    Uses bilinear interpolation to calculate value.
    
    - parameter mid: 2-component vector with ranges in [0.0, 1.0] determining point to interpolate to.
    - returns: Bilinearly interpolated value.
    */
    public func interpolate(mid:CGFloat) -> T {
        
        let midVec:CGFloat
        if self.shouldSmooth {
            let x = mid * mid * (3.0 - 2.0 * mid)
            midVec = x
        } else {
            midVec = mid
        }
        
        return linearlyInterpolate(midVec, left: self.left, right: self.right)
        
    }//trilinearly interpolate
    
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