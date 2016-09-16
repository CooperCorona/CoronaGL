//
//  NoiseArray3D.swift
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
import GameplayKit

// MARK: - Noise Array
///See http://paulbourke.net/texture_colour/perlin/perlin.h for implementation details.
open class NoiseArray3D {
    
    public typealias NoiseType = CGFloat
    
    ///Total number of gradients / permutations.
    open static let totalCount = 256
    
    ///Total elements of gradient / permutation arrays.
    open static let arrayCount = NoiseArray3D.totalCount * 2 + 2
    
    ///Used to clamp indices to correct range.
    open static let permutationClamp = 255
    
    ///3-Component Normalized Vectors of index's corresponding gradient.
    open fileprivate(set) var gradients = [SCVector3](repeating: SCVector3(), count: NoiseArray3D.arrayCount)
    
    ///Scrambled indices of gradients array.
    open fileprivate(set) var permutations = [Int](repeating: 0, count: NoiseArray3D.arrayCount)
    
    ///Number used to seed pseudo random number generator.
    open let seed:UInt32
    fileprivate let random:GKMersenneTwisterRandomSource
    
    ///Whether the noise should be calculated by smoothing the interpolation.
    open var shouldSmooth = true
    
    ///Initialize NoiseArray3D with noise corresponding to seed.
    public init(seed:UInt32 = 1) {
        
        self.seed = seed
        self.random = GKMersenneTwisterRandomSource(seed: UInt64(seed))
        
        //Generate pseudo random gradients (which
        //are always the same for the same seeds)
        for iii in 0..<NoiseArray3D.totalCount {
            
            let x = self.randomValue()
            let y = self.randomValue()
            let z = self.randomValue()
            let v = SCVector3(x: x, y: y, z: z)
            
            self.gradients[iii] = v.unit()
            self.permutations[iii] = iii
        }
        
        //Scramble list of permutations
        for iii in 0..<NoiseArray3D.totalCount {
            let scrambleIndex = abs(self.random.nextInt()) % NoiseArray3D.totalCount
            let storedValue = self.permutations[iii]
            self.permutations[iii] = self.permutations[scrambleIndex]
            self.permutations[scrambleIndex] = storedValue
        }
        
        //Add gradients / permutations to extra elements
        //at the end of each array to prevent overflow concerns
        for iii in 0..<(NoiseArray3D.totalCount + 2) {
            self.permutations[iii + NoiseArray3D.totalCount]  = self.permutations[iii]
            self.gradients[iii + NoiseArray3D.totalCount]     = self.gradients[iii]
        }
        
    }//initialize
    
    fileprivate func randomValue() -> CGFloat {
        return CGFloat(abs(self.random.nextInt()) % (NoiseArray3D.totalCount * 2 + 1) - NoiseArray3D.totalCount) / CGFloat(NoiseArray3D.totalCount)
    }
    
    /**
    Get value of noise at XYZ position *vec*.
    
    - parameter vec: XYZ position to calculate noise at.
    - returns: Value of noise at *vec* in range [-1.0, 1.0]
    */
    open func noiseAt(_ vec:SCVector3) -> NoiseType {
        
        let xComponents = self.getComponentsAt(vec.x)
        let yComponents = self.getComponentsAt(vec.y)
        let zComponents = self.getComponentsAt(vec.z)
        
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
        
        let yPermutationIndexLL = self[xPermutationIndexL  + yComponents.lowerIndex]
        let yPermutationIndexLU = self[xPermutationIndexL  + yComponents.upperIndex]
        let yPermutationIndexUL = self[xPermutationIndexU  + yComponents.lowerIndex]
        let yPermutationIndexUU = self[xPermutationIndexU  + yComponents.upperIndex]
        
        let permutationIndexLLL = self[yPermutationIndexLL + zComponents.lowerIndex]
        let permutationIndexULL = self[yPermutationIndexUL + zComponents.lowerIndex]
        let permutationIndexLUL = self[yPermutationIndexLU + zComponents.lowerIndex]
        let permutationIndexUUL = self[yPermutationIndexUU + zComponents.lowerIndex]
        let permutationIndexLLU = self[yPermutationIndexLL + zComponents.upperIndex]
        let permutationIndexULU = self[yPermutationIndexUL + zComponents.upperIndex]
        let permutationIndexLUU = self[yPermutationIndexLU + zComponents.upperIndex]
        let permutationIndexUUU = self[yPermutationIndexUU + zComponents.upperIndex]
        
        let permutationIndices = [
            permutationIndexLLL,
            permutationIndexULL,
            permutationIndexLUL,
            permutationIndexUUL,
            permutationIndexLLU,
            permutationIndexULU,
            permutationIndexLUU,
            permutationIndexUUU,
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
        let offsetLLL = SCVector3(x: xComponents.preDistance,  y: yComponents.preDistance,  z: zComponents.preDistance)
        let offsetULL = SCVector3(x: xComponents.postDistance, y: yComponents.preDistance,  z: zComponents.preDistance)
        let offsetLUL = SCVector3(x: xComponents.preDistance,  y: yComponents.postDistance, z: zComponents.preDistance)
        let offsetUUL = SCVector3(x: xComponents.postDistance, y: yComponents.postDistance, z: zComponents.preDistance)
        let offsetLLU = SCVector3(x: xComponents.preDistance,  y: yComponents.preDistance,  z: zComponents.postDistance)
        let offsetULU = SCVector3(x: xComponents.postDistance, y: yComponents.preDistance,  z: zComponents.postDistance)
        let offsetLUU = SCVector3(x: xComponents.preDistance,  y: yComponents.postDistance, z: zComponents.postDistance)
        let offsetUUU = SCVector3(x: xComponents.postDistance, y: yComponents.postDistance, z: zComponents.postDistance)
        let offsets = [
            offsetLLL,
            offsetULL,
            offsetLUL,
            offsetUUL,
            offsetLLU,
            offsetULU,
            offsetLUU,
            offsetUUU
        ]
        
        let tArray = TrilinearArray<CGFloat>() { index, vector in
            let gradientIndex = permutationIndices[index]
            let gradient = self.gradients[gradientIndex]
            let offset   = offsets[index]
            return gradient.dot(offset)
        }
        tArray.shouldSmooth = self.shouldSmooth
        
        /*
        *  offsetLLL is guarunteed to be positive and can
        *  also be thought of as the desired point to
        *  interpolate to relative to the cube defined
        *  by the 8 calculated values.
        */
        return tArray.interpolate(offsetLLL)
    }//get noise at corresponding vector
    
    /**
    Gets value noise at XYZ position *vec*, scaling and offseting
    value to range [0.0, 1.0]. Identical to calling
    noiseAt(_) * 0.5 + 0.5.
    
    - parameter vec: XYZ position to calculate noise at.
    - returns: Value of noise at *vec* in range [0.0, 1.0]
    */
    open func positiveNoiseAt(_ vec:SCVector3) -> NoiseType {
        return self.noiseAt(vec) * 0.5 + 0.5
    }
    
    /**
    Get components such as lower and upper indices and distance vectors.
    
    - parameter value: X, Y, or Z value of position vector.
    
    - returns: **Lower Index** Index of permutation that is less than or equal to corresponding vector.
    - returns: **Upper Index** Index of permutation that is greater than corresponding vector.
    - returns: **Pre Distance** Distance in range [0.0, 1.0) of value from lower index.
    - returns: **Post Distance** Distance in range [-1.0, 0.0) of value from upper index.
    */
    fileprivate func getComponentsAt(_ value:CGFloat) -> (lowerIndex:Int, upperIndex:Int, preDistance:CGFloat, postDistance:CGFloat) {
        let lowerIndex = Int(value) & NoiseArray3D.permutationClamp
        let upperIndex = (lowerIndex + 1) & NoiseArray3D.permutationClamp
        let preDistance = value - floor(value)
        let postDistance = preDistance - 1.0
        return (lowerIndex, upperIndex, preDistance, postDistance)
    }
    
    ///Convenience accessor to *permutations* (read-only).
    fileprivate subscript(index:Int) -> Int {
        return self.permutations[index]
    }
}
