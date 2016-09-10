//
//  NoiseArray1D.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 10/13/15.
//  Copyright © 2015 Cooper Knaak. All rights reserved.
//

import Foundation

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

public class NoiseArray1D {
    
    public typealias NoiseType = CGFloat
    
    ///Total number of gradients / permutations.
    public static let totalCount = 256
    
    ///Total elements of gradient / permutation arrays.
    public static let arrayCount = NoiseArray1D.totalCount * 2 + 2
    
    ///Used to clamp indices to correct range.
    public static let permutationClamp = 255
    
    ///2-Component Normalized Vectors of index's corresponding gradient.
    public private(set) var gradients = [CGFloat](count: NoiseArray1D.arrayCount, repeatedValue: 0.0)
    
    ///Scrambled indices of gradients array.
    public private(set) var permutations = [Int](count: NoiseArray1D.arrayCount, repeatedValue: 0)
    
    ///Number used to seed pseudo random number generator.
    public let seed:UInt32
    
    ///Whether the interpolation should be smoothed.
    public var shouldSmooth = true
    
    ///Initialize NoiseArray1D with noise corresponding to seed.
    public init(seed:UInt32 = 1) {
        
        self.seed = seed
        
        //Seed pseudo random number generator
        srandom(seed)
        
        //Generate pseudo random gradients (which
        //are always the same for the same seeds)
        for iii in 0..<NoiseArray1D.totalCount {
            
            let p = self.randomValue()
            
            self.gradients[iii] = p
            self.permutations[iii] = iii
        }
        
        //Scramble list of permutations
        for iii in 0..<NoiseArray1D.totalCount {
            let scrambleIndex = random() % NoiseArray1D.totalCount
            let storedValue = self.permutations[iii]
            self.permutations[iii] = self.permutations[scrambleIndex]
            self.permutations[scrambleIndex] = storedValue
        }
        
        //Add gradients / permutations to extra elements
        //at the end of each array to prevent overflow concerns
        for iii in 0..<(NoiseArray1D.totalCount + 2) {
            self.permutations[iii + NoiseArray1D.totalCount]  = self.permutations[iii]
            self.gradients[iii + NoiseArray1D.totalCount]     = self.gradients[iii]
        }
        
    }//initialize
    
    private func randomValue() -> CGFloat {
        return CGFloat(random() % (NoiseArray1D.totalCount * 2 + 1) - NoiseArray1D.totalCount) / CGFloat(NoiseArray1D.totalCount)
    }
    
    /**
    Get value of noise at XY position *vec*.
    
    - parameter vec: XY position to calculate noise at.
    - returns: Value of noise at *vec* in range [-1.0, 1.0]
    */
    public func noiseAt(vec:CGFloat) -> NoiseType {
        
        let xComponents = self.getComponentsAt(vec)
        
        /*
        *  In these variables
        *  L = Lower;  U = Upper
        *
        *  They all take the form PermutationIndex???,
        *  where the first ? is the x-component,
        *  the second ? is the y-component,
        *  and the third ? is the z-component.
        *
        *  --  Thus, the left-bottom-back index would be
        *      permutationIndexLLL, because each of left,
        *      bottom, and back refer to the Lower index.
        *
        *  --  The right-bottom-front index would be
        *      permutationIndexULU, because right refers
        *      to Upper, bottom refers to Lower, and
        *      front refers to Upper
        *
        *
        */
        let xPermutationIndexL = self[xComponents.lowerIndex]
        let xPermutationIndexU = self[xComponents.upperIndex]
        
        
        let permutationIndices = [
            xPermutationIndexL,
            xPermutationIndexU
        ]
        
        /*
        *  We must compute the dot product of the position vector
        *  (relative to the nearest lower grid coordinate), referred
        *  to as the offset vector, and the gradient vector. Thus, I
        *  need to calculate all the offset vectors and place them
        *  appropriately in an array.
        *
        *  Naming conventions are the same as for the permutation indices.
        */
        let offsetL = xComponents.preDistance
        let offsetU = xComponents.postDistance
        let offsets = [
            offsetL,
            offsetU
        ]
        
        let lArray = LinearArray<CGFloat>() { index, vector in
            let gradientIndex = permutationIndices[index]
            let gradient = self.gradients[gradientIndex]
            let offset   = offsets[index]
            return gradient * offset
        }
        lArray.shouldSmooth = self.shouldSmooth
        
        /*
        *  offsetLLL is guarunteed to be positive and can
        *  also be thought of as the desired point to
        *  interpolate to relative to the cube defined
        *  by the 8 calculated values.
        */
        return lArray.interpolate(offsetL)
    }//get noise at corresponding vector
    
    /**
    Gets value noise at XY position *vec*, scaling and offseting
    value to range [0.0, 1.0]. Identical to calling
    noiseAt(_) * 0.5 + 0.5.
    
    - parameter vec: XY position to calculate noise at.
    - returns: Value of noise at *vec* in range [0.0, 1.0]
    */
    public func positiveNoiseAt(vec:CGFloat) -> NoiseType {
        return self.noiseAt(vec) * 0.5 + 0.5
    }
    
    /**
    Get components such as lower and upper indices and distance vectors.
    
    - parameter value: X or Y value of position vector.
    
    - returns: **Lower Index** Index of permutation that is less than or equal to corresponding vector.
    - returns: **Upper Index** Index of permutation that is greater than corresponding vector.
    - returns: **Pre Distance** Distance in range [0.0, 1.0) of value from lower index.
    - returns: **Post Distance** Distance in range [-1.0, 0.0) of value from upper index.
    */
    private func getComponentsAt(value:CGFloat) -> (lowerIndex:Int, upperIndex:Int, preDistance:CGFloat, postDistance:CGFloat) {
        let lowerIndex = Int(value) & NoiseArray1D.permutationClamp
        let upperIndex = (lowerIndex + 1) & NoiseArray1D.permutationClamp
        let preDistance = value - floor(value)
        let postDistance = preDistance - 1.0
        return (lowerIndex, upperIndex, preDistance, postDistance)
    }
    
    ///Convenience accessor to *permutations* (read-only).
    private subscript(index:Int) -> Int {
        return self.permutations[index]
    }
}
