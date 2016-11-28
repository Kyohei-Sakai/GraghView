//
//  GraghViewCell.swift
//  GraghView
//
//  Created by 酒井恭平 on 2016/11/27.
//  Copyright © 2016年 酒井恭平. All rights reserved.
//

import UIKit

// MARK: - GraghViewCell Class

class GraghViewCell: UIView {
    // MARK: - Pablic properties
    
    var comparisonValueY: CGFloat? {
        guard let comparisonValueHeight = comparisonValueHeight else { return nil }
        return y - comparisonValueHeight
    }
    
    // MARK: - Private properties
    
    // MARK: Shared
    
    private var graghView: GraghView?
    private var style: GraghStyle?
    private var dateStyle: GraghViewDateStyle?
    private var dataType: GraghViewDataType?
    
    private var graghValue: CGFloat
    private var maxGraghValue: CGFloat? { return graghView?.maxGraghValue }
    
    private var date: Date?
    private var comparisonValue: CGFloat?
    
    private var maxBarAreaHeight: CGFloat? {
        guard let maxGraghValue = maxGraghValue else { return nil }
        return maxGraghValue / LayoutProportion.maxGraghValueRate
    }
    
    private var barAreaHeight: CGFloat { return frame.height * LayoutProportion.barAreaHeightRate }
    
    private var barHeigth: CGFloat? {
        guard let maxBarAreaHeight = maxBarAreaHeight else { return nil }
        return barAreaHeight * graghValue / maxBarAreaHeight
    }
    
    // barの終点のY座標・roundのposition
    private var toY: CGFloat? {
        guard let barHeigth = barHeigth else { return nil }
        return y - barHeigth
    }
    
    private var labelHeight: CGFloat { return (frame.height - barAreaHeight) / 2 }
    
    private var comparisonValueHeight: CGFloat? {
        guard let maxBarAreaHeight = maxBarAreaHeight, let comparisonValue = comparisonValue else { return nil }
        return barAreaHeight * comparisonValue / maxBarAreaHeight
    }
    
    // MARK: Only Bar
    
    private var barWidth: CGFloat { return frame.width * LayoutProportion.barWidthRate }
    
    // barの始点のX座標（＝終点のX座標）
    private var x: CGFloat { return frame.width / 2 }
    // barの始点のY座標（上下に文字列表示用の余白がある）
    private var y: CGFloat { return barAreaHeight + (frame.height - barAreaHeight) / 2 }
    
    // MARK: - Initializers
    
    init(frame: CGRect, graghValue: CGFloat, date: Date, comparisonValue: CGFloat, target graghView: GraghView? = nil) {
        self.graghView = graghView
        self.style = graghView?.graghStyle
        self.dateStyle = graghView?.dateStyle
        self.dataType = graghView?.dataType
        
        self.graghValue = graghValue
        self.date = date
        self.comparisonValue = comparisonValue
        
        super.init(frame: frame)
        self.backgroundColor = LayoutProportion.GraghBackgroundColor
    }
    
    // storyboardで生成する時
    required init?(coder aDecoder: NSCoder) {
        self.graghValue = 0
        super.init(coder: aDecoder)
        //        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Override
    
    override func draw(_ rect: CGRect) {
        guard let style = style else {
            return
        }
        
        if let toY = toY {
            // Graghを描画
            switch style {
            case .bar: drawBar(from: CGPoint(x: x, y: y), to: CGPoint(x: x, y: toY))
            case .round: drawRound(point: CGPoint(x: x, y: toY))
            }
        }
        
        // over labelを表示
        drawLabel(centerX: x, centerY: labelHeight / 2, width: rect.width, height: labelHeight, text: overTextFormatter(from: graghValue))
        
        if let date = date {
            // under labelを表示
            drawLabel(centerX: x, centerY: rect.height - labelHeight / 2, width: rect.width, height: labelHeight, text: underTextFormatter(from: date))
        }
        
    }
    
    
    // MARK: - Private methods
    
    // MARK: Under Label's text format
    private func underTextFormatter(from date: Date) -> String {
        guard let dateStyle = dateStyle else {
            return ""
        }
        
        let dateFormatter = DateFormatter()
        
        switch dateStyle {
        case .year: dateFormatter.dateFormat = "yyyy"
        case .month: dateFormatter.dateFormat = "yyyy/MM"
        case .day: dateFormatter.dateFormat = "MM/dd"
        }
        
        return dateFormatter.string(from: date)
    }
    
    // MARK: Over Label's text format
    private func overTextFormatter(from value: CGFloat) -> String {
        guard let dataType = dataType else {
            return ""
        }
        
        switch dataType {
        case .normal: return String("\(value)")
        case .yen: return String("\(Int(value)) 円")
        }
        
    }
    
    // MARK: Drawing
    
    private func drawBar(from startPoint: CGPoint, to endPoint: CGPoint) {
        let BarPath = UIBezierPath()
        BarPath.move(to: startPoint)
        BarPath.addLine(to: endPoint)
        BarPath.lineWidth = barWidth
        LayoutProportion.barColor.setStroke()
        BarPath.stroke()
    }
    
    private func drawRound(point: CGPoint) {
        let origin = CGPoint(x: point.x - LayoutProportion.roundSize / 2, y: point.y - LayoutProportion.roundSize / 2)
        let size = CGSize(width: LayoutProportion.roundSize, height: LayoutProportion.roundSize)
        let round = UIBezierPath(ovalIn: CGRect(origin: origin, size: size))
        LayoutProportion.roundColor.setFill()
        round.fill()
        
    }
    
    private func drawLabel(centerX x: CGFloat, centerY y: CGFloat, width: CGFloat, height: CGFloat, text: String) {
        let label: UILabel = UILabel()
        label.frame = CGRect(x: 0, y: 0, width: width, height: height)
        label.center = CGPoint(x: x, y: y)
        label.text = text
        label.textAlignment = .center
        label.font = label.font.withSize(10)
        label.backgroundColor = LayoutProportion.labelBackgroundColor
        addSubview(label)
    }
    
    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
