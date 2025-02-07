//
//  File.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/6/25.
//


//
//  paragraphAlignmentFunctions.swift
//  UseNSAttribute
//
//  Created by Steven Hertz on 2/5/25.
//

import Foundation
import UIKit


    /// 📌 Returns a centered paragraph style
func centeredParagraphStyle() -> NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    return style
}

    /// 📌 Returns a justified paragraph style
func justifiedParagraphStyle() -> NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = .justified
    return style
}

    /// 📌 Returns a left-aligned paragraph style
func leftAlignedParagraphStyle() -> NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = .left
    return style
}
