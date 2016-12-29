//
//  Extension.swift
//  AVPlayer
//
//  Created by SW on 2016/11/17.
//  Copyright © 2016年 WY. All rights reserved.
//

import Foundation
import UIKit

extension UIImage{
    
   class func originImage(image:UIImage,scaleToSize size:CGSize) -> UIImage{
        
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
    
    func imageWithTintColor(tintColor:UIColor) -> UIImage{
        
        return self.imageWithTintColor(tintColor: tintColor, blendMode: CGBlendMode.destinationIn)
    }
    
    private func imageWithTintColor(tintColor:UIColor,blendMode:CGBlendMode) -> UIImage{
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        tintColor.setFill()
        
        let bounds = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIRectFill(bounds)
        self.draw(in: bounds, blendMode: blendMode, alpha: 1.0)
        if blendMode != CGBlendMode.destinationIn {
            
            self.draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1.0)
            
        }
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }
}
