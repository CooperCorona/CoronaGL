//
//  NoiseArray2D.swift
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
import GameplayKit

open class NoiseArray2D {
    
    public typealias NoiseType = CGFloat
    
    ///Total number of gradients / permutations.
    open static let totalCount = 256
    
    ///Total elements of gradient / permutation arrays.
    open static let arrayCount = NoiseArray2D.totalCount * 2 + 2
    
    ///Used to clamp indices to correct range.
    open static let permutationClamp = 255
    
    ///2-Component Normalized Vectors of index's corresponding gradient.
    open fileprivate(set) var gradients = [CGPoint](repeating: CGPoint.zero, count: NoiseArray2D.arrayCount)
    
    ///Scrambled indices of gradients array.
    open fileprivate(set) var permutations = [Int](repeating: 0, count: NoiseArray2D.arrayCount)
    
    ///Number used to seed pseudo random number generator.
    open let seed:UInt32
    fileprivate let random:GKMersenneTwisterRandomSource
    
    ///Whether the noise should be calculated by smoothing the interpolation.
    open var shouldSmooth = true
    
    ///Initialize NoiseArray2D with noise corresponding to seed.
    public init(seed:UInt32 = 1) {
        self.seed = seed
        //Seed pseudo random number generator
        self.random = GKMersenneTwisterRandomSource(seed: UInt64(seed))
        
        //Generate pseudo random gradients (which
        //are always the same for the same seeds)
        for iii in 0..<NoiseArray2D.totalCount {
            
            let angle = self.randomValue() * (2.0 * CGFloat(M_PI))
            let p = CGPoint(angle: angle, length: 1.0)
            
            self.gradients[iii] = p
            self.permutations[iii] = iii
        }
        
        //Scramble list of permutations
        for iii in 0..<NoiseArray2D.totalCount {
            let scrambleIndex = abs(self.random.nextInt()) % NoiseArray2D.totalCount
            let storedValue = self.permutations[iii]
            self.permutations[iii] = self.permutations[scrambleIndex]
            self.permutations[scrambleIndex] = storedValue
        }
        
        //Add gradients / permutations to extra elements
        //at the end of each array to prevent overflow concerns
        for iii in 0..<(NoiseArray2D.totalCount + 2) {
            self.permutations[iii + NoiseArray2D.totalCount]  = self.permutations[iii]
            self.gradients[iii + NoiseArray2D.totalCount]     = self.gradients[iii]
        }
        
    }//initialize
    
    fileprivate func randomValue() -> CGFloat {
        return CGFloat(abs(self.random.nextInt()) % (NoiseArray2D.totalCount * 2 + 1) - NoiseArray2D.totalCount) / CGFloat(NoiseArray2D.totalCount)
    }
    
    /**
    Get value of noise at XY position *vec*.
    
    - parameter vec: XY position to calculate noise at.
    - returns: Value of noise at *vec* in range [-1.0, 1.0]
    */
    open func noiseAt(_ vec:CGPoint) -> NoiseType {
        
        let xComponents = self.getComponentsAt(vec.x)
        let yComponents = self.getComponentsAt(vec.y)
        
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
        
        let permutationIndexLL = self[xPermutationIndexL  + yComponents.lowerIndex]
        let permutationIndexLU = self[xPermutationIndexL  + yComponents.upperIndex]
        let permutationIndexUL = self[xPermutationIndexU  + yComponents.lowerIndex]
        let permutationIndexUU = self[xPermutationIndexU  + yComponents.upperIndex]
        
        
        let permutationIndices = [
            permutationIndexLL,
            permutationIndexUL,
            permutationIndexLU,
            permutationIndexUU
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
        let offsetLL = CGPoint(x: xComponents.preDistance,  y: yComponents.preDistance)
        let offsetUL = CGPoint(x: xComponents.postDistance, y: yComponents.preDistance)
        let offsetLU = CGPoint(x: xComponents.preDistance,  y: yComponents.postDistance)
        let offsetUU = CGPoint(x: xComponents.postDistance, y: yComponents.postDistance)
        let offsets = [
            offsetLL,
            offsetUL,
            offsetLU,
            offsetUU
        ]
        
        let bArray = BilinearArray<CGFloat>() { index, vector in
            let gradientIndex = permutationIndices[index]
            let gradient = self.gradients[gradientIndex]
            let offset   = offsets[index]
            return gradient.dot(offset)
        }
        bArray.shouldSmooth = self.shouldSmooth
        
        /*
        *  offsetLLL is guarunteed to be positive and can
        *  also be thought of as the desired point to
        *  interpolate to relative to the cube defined
        *  by the 8 calculated values.
        */
        return bArray.interpolate(offsetLL)
    }//get noise at corresponding vector
    
    /**
    Gets value noise at XY position *vec*, scaling and offseting
    value to range [0.0, 1.0]. Identical to calling
    noiseAt(_) * 0.5 + 0.5.
    
    - parameter vec: XY position to calculate noise at.
    - returns: Value of noise at *vec* in range [0.0, 1.0]
    */
    open func positiveNoiseAt(_ vec:CGPoint) -> NoiseType {
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
    fileprivate func getComponentsAt(_ value:CGFloat) -> (lowerIndex:Int, upperIndex:Int, preDistance:CGFloat, postDistance:CGFloat) {
        let lowerIndex = Int(value) & NoiseArray2D.permutationClamp
        let upperIndex = (lowerIndex + 1) & NoiseArray2D.permutationClamp
        let preDistance = value - floor(value)
        let postDistance = preDistance - 1.0
        return (lowerIndex, upperIndex, preDistance, postDistance)
    }
    
    ///Convenience accessor to *permutations* (read-only).
    fileprivate subscript(index:Int) -> Int {
        return self.permutations[index]
    }
}
