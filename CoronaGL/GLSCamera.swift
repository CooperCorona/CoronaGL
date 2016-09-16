//
//  GLSCamera.swift
//  Gravity
//
//  Created by Cooper Knaak on 2/19/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
import CoronaConvenience
import CoronaStructures

open class GLSCamera: NSObject {
    
    open var position:CGPoint { return self.controller?.container.position ?? CGPoint.zero }
    open var size = CGSize.zero
    open weak var controller:GLKOmniController? = nil
    
    open func centerForPosition(position:CGPoint) -> CGPoint {
        
        if let cont = self.controller {
            
            let vSize = cont.getFrame().size
            
            return CGPoint(x: vSize.width / 2.0 - position.x, y: vSize.height / 2.0 - position.y)
        } else {
            return CGPoint(x: -1.0, y: -1.0)
        }
        
    }//get center of container (so that 'position' is in center of screen)
    
    open func clampCenter(center:CGPoint) -> CGPoint {
        
        if let cont = self.controller {
            
            let vSize = cont.getFrame().size
            
            //These coordinates assume that the given andreturned
            //'center' correspond to a bottom-left origin
            let maxX:CGFloat = 0.0
            let maxY:CGFloat = 0.0
            let minX = vSize.width - self.size.width
            let minY = vSize.height - self.size.height
            
            let xpos = min(max(center.x, minX), maxX)
            let ypos = min(max(center.y, minY), maxY)
            
            return CGPoint(x: xpos, y: ypos)
            
        } else {
            return center
        }
        
    }//clamp center so you never see off-screen
    
    
    open func convertPointToOpenGL(point:CGPoint) -> CGPoint {
        
        var glPoint = point
        if let vSize = self.controller?.getFrame().size {
            glPoint = CGPoint(x: glPoint.x, y: vSize.height - glPoint.y)
        }
        
        return glPoint - self.position
    }//convert UI point to GL point
    
    open func convertPointFromOpenGL(point:CGPoint) -> CGPoint {
        
        var glPoint = point + self.position
        
        if let vSize = self.controller?.getFrame().size {
            glPoint = CGPoint(x: glPoint.x, y: vSize.height - glPoint.y)
        }
        
        return glPoint
    }//convert GL point to UI point
    
    open func convertRectToOpenGL(rect:CGRect) -> CGRect {
        var origin = rect.origin
        var maxPoint = origin + rect.size.getCGPoint()
        
        origin = self.convertPointToOpenGL(point: origin)
        maxPoint = self.convertPointToOpenGL(point: maxPoint)
        
        var glRect = CGRect(x: origin.x, y: origin.y, width: maxPoint.x - origin.x, height: maxPoint.y - origin.y)
        return glRect.standardized
    }//convert rect to OpenGL
    
    open func convertRectFromOpenGL(rect:CGRect) -> CGRect {
        var origin = rect.origin
        var maxPoint = origin + rect.size.getCGPoint()
        
        origin = self.convertPointFromOpenGL(point: origin)
        maxPoint = self.convertPointFromOpenGL(point: maxPoint)
        
        var uiRect = CGRect(x: origin.x, y: origin.y, width: maxPoint.x - origin.x, height: maxPoint.y - origin.y)
        return uiRect.standardized
    }//convert rect to OpenGL
}

#endif
