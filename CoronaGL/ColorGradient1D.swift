//
//  ColorGradient1D.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 5/27/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

open class ColorGradient1D: NSObject {
    
    // MARK: - Types
    public typealias ColorArray = [(color:SCVector4, weight:CGFloat)]
    public typealias ColorType  = GLubyte
    
    // MARK: - Properties
    
    open let anchors:ColorArray
    open let colorArray:[ColorType]
    open let size = 256
    
    open let isSmoothed:Bool
    
    // MARK: - Setup
    
    public init(colorsAndWeights:ColorArray, smoothed:Bool = true) {
        
        self.isSmoothed = smoothed
        self.anchors = colorsAndWeights
        
        var colors:[SCVector4] = []
        var weights:[CGFloat] = []
        for cur in colorsAndWeights {
            colors.append(cur.color)
            weights.append(cur.weight)
        }
        while colors.count < 2 {
            colors.append(SCVector4.whiteColor)
            weights.append(1.0)
        }
        
        //Create Array (multiply by 4 because their are 4 components per color)
        var texCols = [ColorType](repeating: 255, count: size * 4)
        var intWeights:[Int] = []
        var lastIntegerValue = 0
        for cur in weights {
            let integerValue = Int(cur * CGFloat(size - 1)) & 255
            if (integerValue < lastIntegerValue) {
                intWeights.append(lastIntegerValue)
            } else {
                intWeights.append(integerValue)
                lastIntegerValue = integerValue
            }
        }
        
        //        var curWeightIndex = intWeights[0]
        let firstCol = colors[0]
        for jjj in 0..<intWeights[0] {
            texCols[jjj * 4    ] = ColorType(firstCol.r * 255)
            texCols[jjj * 4 + 1] = ColorType(firstCol.g * 255)
            texCols[jjj * 4 + 2] = ColorType(firstCol.b * 255)
            texCols[jjj * 4 + 3] = ColorType(firstCol.a * 255)
        }
        
        
        //        var nexWeightIndex = intWeights[1]
        for iii in 0..<(colors.count - 1) {
            let curCol = colors[iii]
            let nexCol = colors[iii + 1]
            
            let curWeightIndex = intWeights[iii]
            let nexWeightIndex = intWeights[iii + 1]
            
            for jjj in curWeightIndex..<nexWeightIndex {
                var percentBetween = CGFloat(jjj - curWeightIndex) / CGFloat(nexWeightIndex - curWeightIndex)
                
                if smoothed {
                    percentBetween = smoothstep(percentBetween)
                }
                
                let currentColor = linearlyInterpolate(percentBetween, left: curCol, right: nexCol)
                texCols[jjj * 4    ] = ColorType(currentColor.r * 255)
                texCols[jjj * 4 + 1] = ColorType(currentColor.g * 255)
                texCols[jjj * 4 + 2] = ColorType(currentColor.b * 255)
                texCols[jjj * 4 + 3] = ColorType(currentColor.a * 255)
            }
        }
        
        //Last color (and weight) is guarunteed to exist,
        //but I optionally unwrap anyways.
        if let lastCol = colors.last, let nexWeightIndex = intWeights.last {
            for jjj in nexWeightIndex..<size {
                texCols[jjj * 4    ] = ColorType(lastCol.r * 255)
                texCols[jjj * 4 + 1] = ColorType(lastCol.g * 255)
                texCols[jjj * 4 + 2] = ColorType(lastCol.b * 255)
                texCols[jjj * 4 + 3] = ColorType(lastCol.a * 255)
            }
        }
        
        self.colorArray = texCols
        
        //        super.init()
        
    }//initialize
    
    /**
    Initializes a ColorGradient1D object with colors at weights.
    
    - parameter colors: The colors to use at each anchor.
    - parameter weights: The position of each anchor. If there are not enough anchors, array is padded with 1.0.
    - parameter smoothed: Whether to smooth the gradient.
    */
    public convenience init(colors:[SCVector4], weights:[CGFloat], smoothed:Bool = true) {
        
        var array:ColorArray = []
        for (iii, color) in colors.enumerated() {
            let weight = object(weights, atIndex: iii) ?? 1.0
            let tuple = (color: color, weight: weight)
            array.append(tuple)
        }
        
        self.init(colorsAndWeights: array, smoothed: smoothed)
    }
    
    public convenience init(colors:[SCVector4], smoothed:Bool = true) {
        
        var colorsAndWeights:ColorArray = []
        
        for (iii, col) in colors.enumerated() {
            let weight = CGFloat(iii) / CGFloat(colors.count - 1)
            colorsAndWeights.append((color: col, weight: weight))
        }
        
        self.init(colorsAndWeights: colorsAndWeights, smoothed: smoothed)
    }//initialize
    
    // MARK: - Logic
    
    open subscript(percent:CGFloat) -> SCVector4 {
        let index = Int(percent * CGFloat(self.size - 1))
        
        let r = self.colorArray[index * 4]
        let g = self.colorArray[index * 4 + 1]
        let b = self.colorArray[index * 4 + 2]
        let a = self.colorArray[index * 4 + 3]
        return SCVector4(x: CGFloat(r) / 255.0, y: CGFloat(g) / 255.0, z: CGFloat(b) / 255.0, w: CGFloat(a) / 255.0)
    }
    
    open func blendColor(_ color:SCVector4) -> ColorGradient1D {
        var anchors:ColorArray = []
        for anchor in self.anchors {
            let blendedColor = linearlyInterpolate(color.a, left: anchor.color.xyz, right: color.xyz)
            anchors.append((color: SCVector4(vector3: blendedColor, wValue: anchor.color.a), weight: anchor.weight))
        }
        return ColorGradient1D(colorsAndWeights: anchors, smoothed: self.isSmoothed)
    }
    
    #if os(iOS)
    // MARK: - Quick Look Debug
    open func getImage(height:CGFloat = 32.0) -> UIImage {
        
        UIGraphicsBeginImageContext(CGSize(width: CGFloat(self.size), height: height))
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        
        for iii in 0..<self.size {
            let percent = CGFloat(iii) / CGFloat(self.size - 1)
            let color = UIColor(vector4: self[percent])
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: CGFloat(iii), y: 0.0, width: 1.0, height: height))
        }
        
        let im = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        
        return im
    }
    
    open func debugQuickLookObject() -> AnyObject {
        return self.getImage()
    }
    #endif
    
    // MARK: - Static Gradients
    
    open static let grayscaleGradient:ColorGradient1D = ColorGradient1D(colors: [SCVector4.blackColor, SCVector4.whiteColor])
    
    open static let rainbowGradient = ColorGradient1D(colors: SCVector4.rainbowColors)
    
    open static let fireGradient = ColorGradient1D(colorsAndWeights: [(SCVector4.blackColor, 0.25), (SCVector4.redColor, 0.5), (SCVector4.orangeColor, 0.7), (SCVector4.yellowColor, 0.75), (SCVector4.whiteColor, 1.0)])
    
    open static let hueGradient = ColorGradient1D(colors: [
        SCVector4.redColor,
        SCVector4.yellowColor,
        SCVector4.greenColor,
        SCVector4.cyanColor,
        SCVector4.blueColor,
        SCVector4.magentaColor,
        SCVector4.redColor
    ], smoothed: false)
    
}


public func ==(lhs:(SCVector4, CGFloat), rhs:(SCVector4, CGFloat)) -> Bool {
    return (lhs.0 ~= rhs.0) && (lhs.1 ~= rhs.1)
}

public func !=(lhs:(SCVector4, CGFloat), rhs:(SCVector4, CGFloat)) -> Bool {
    return !(lhs == rhs)
}

public func ==(lhs:ColorGradient1D.ColorArray, rhs:ColorGradient1D.ColorArray) -> Bool {
    
    if lhs.count != rhs.count {
        return false
    }
    
    //Both arrays are guarunteed to have same count.
    for iii in 0..<lhs.count {
        if lhs[iii] != rhs[iii] {
            return false
        }
    }
    
    return true
}

public func !=(lhs:ColorGradient1D.ColorArray, rhs:ColorGradient1D.ColorArray) -> Bool {
    return !(lhs == rhs)
}

public func ==(lhs:ColorGradient1D, rhs:ColorGradient1D) -> Bool {
    
    if lhs.isSmoothed != rhs.isSmoothed {
        return false
    }
    
    if lhs.anchors != rhs.anchors {
        return false
    }
    
    return true
}
