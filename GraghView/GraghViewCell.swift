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
    
    var endPoint: CGPoint? {
        guard let toY = toY else { return nil }
        return CGPoint(x: x, y: toY)
    }
    
    var comparisonValueY: CGFloat? {
        guard let comparisonValueHeight = comparisonValueHeight, let y = y else { return nil }
        return y - comparisonValueHeight
    }
    
    // MARK: - Private properties
    
    // MARK: Shared
    
    private var graghView: GraghView?
    private var style: GraghStyle?
    private var dateStyle: GraghViewDateStyle?
    private var dataType: GraghViewDataType?
    
    private let cellLayout: GraghView.GraghViewCellLayoutOptions?
    
    private var graghValue: CGFloat
    private var maxGraghValue: CGFloat? { return graghView?.maxGraghValue }
    
    private var date: Date?
    private var comparisonValue: CGFloat?
    
    private var maxBarAreaHeight: CGFloat? {
        guard let maxGraghValue = maxGraghValue, let cellLayout = cellLayout else { return nil }
        return maxGraghValue / cellLayout.maxGraghValueRate
    }
    
    private var barAreaHeight: CGFloat? {
        guard let cellLayout = cellLayout else { return nil }
        return frame.height * cellLayout.barAreaHeightRate
    }
    
    private var barHeigth: CGFloat? {
        guard let maxBarAreaHeight = maxBarAreaHeight, let barAreaHeight = barAreaHeight else { return nil }
        return barAreaHeight * graghValue / maxBarAreaHeight
    }
    
    // barの終点のY座標・roundのposition
    private var toY: CGFloat? {
        guard let barHeigth = barHeigth, let y = y else { return nil }
        return y - barHeigth
    }
    
    private var labelHeight: CGFloat? {
        guard let barAreaHeight = barAreaHeight, let isHidden = cellLayout?.valueLabelIsHidden else { return nil }
        
        if isHidden {
            return frame.height - barAreaHeight
        } else {
            return (frame.height - barAreaHeight) / 2
        }
    }
    
    private var comparisonValueHeight: CGFloat? {
        guard let maxBarAreaHeight = maxBarAreaHeight, let comparisonValue = comparisonValue, let barAreaHeight = barAreaHeight else { return nil }
        return barAreaHeight * comparisonValue / maxBarAreaHeight
    }
    
    // MARK: Only Bar
    
    private var barWidth: CGFloat? {
        guard let cellLayout = cellLayout else { return nil }
        return frame.width * cellLayout.barWidthRate
    }
    
    // barの始点のX座標（＝終点のX座標）
    private var x: CGFloat { return frame.width / 2 }
    // barの始点のY座標
    private var y: CGFloat? {
        guard let barAreaHeight = barAreaHeight, let labelHeight = labelHeight, let isHidden = cellLayout?.valueLabelIsHidden else { return nil }
        
        if isHidden {
            return barAreaHeight
        } else {
            return barAreaHeight + labelHeight / 2
        }
        
    }
    
    // MARK: Only Round
    
    private var roundSize: CGFloat? {
        guard let roundSizeRate = cellLayout?.roundSizeRate else { return nil }
        return roundSizeRate * frame.width
    }
    
    // MARK: - Initializers
    
    init(frame: CGRect, graghValue: CGFloat, date: Date, comparisonValue: CGFloat, target graghView: GraghView? = nil) {
        self.graghView = graghView
        self.style = graghView?.graghStyle
        self.dateStyle = graghView?.dateStyle
        self.dataType = graghView?.dataType
        self.cellLayout = graghView?.cellLayout
        
        self.graghValue = graghValue
        self.date = date
        self.comparisonValue = comparisonValue
        
        super.init(frame: frame)
        self.backgroundColor = cellLayout?.GraghBackgroundColor
        self.graghView?.graghViewCells.append(self)
    }
    
    // storyboardで生成する時
    required init?(coder aDecoder: NSCoder) {
        self.graghValue = 0
        self.cellLayout = nil
        super.init(coder: aDecoder)
//        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Override
    
    override func draw(_ rect: CGRect) {
        guard let style = style else { return }
        
        if let y = y, let endPoint = endPoint {
            // Graghを描画
            switch style {
            case .bar: drawBar(from: CGPoint(x: x, y: y), to: endPoint)
            case .round: drawRound(point: endPoint)
            }
        }
        
        drawOverLabel()
        drawUnderLabel()
        
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
        BarPath.lineWidth = barWidth ?? 0
        cellLayout?.barColor.setStroke()
        BarPath.stroke()
    }
    
    private func drawRound(point: CGPoint) {
        guard let cellLayout = cellLayout, let roundSize = roundSize, !cellLayout.onlyPathLine else { return }
        
        let origin = CGPoint(x: point.x - roundSize / 2, y: point.y - roundSize / 2)
        let size = CGSize(width: roundSize, height: roundSize)
        let round = UIBezierPath(ovalIn: CGRect(origin: origin, size: size))
        cellLayout.roundColor.setFill()
        round.fill()
    }
    
    private func drawOverLabel() {
        guard let cellLayout = cellLayout, let labelHeight = labelHeight else { return }
        
        let overLabel: UILabel = UILabel()
        overLabel.frame = CGRect(x: 0, y: 0, width: frame.width, height: labelHeight)
        overLabel.center = CGPoint(x: x, y: labelHeight / 2)
        overLabel.text = overTextFormatter(from: graghValue)
        overLabel.textAlignment = .center
        overLabel.font = overLabel.font.withSize(10)
        overLabel.backgroundColor = cellLayout.labelBackgroundColor
        overLabel.isHidden = cellLayout.valueLabelIsHidden
        addSubview(overLabel)
    }
    
    private func drawUnderLabel() {
        guard let labelHeight = labelHeight, let date = date else { return }
        
        let underLabel: UILabel = UILabel()
        underLabel.frame = CGRect(x: 0, y: 0, width: frame.width, height: labelHeight)
        underLabel.center = CGPoint(x: x, y: frame.height - labelHeight / 2)
        underLabel.text = underTextFormatter(from: date)
        underLabel.textAlignment = .center
        underLabel.font = underLabel.font.withSize(10)
        underLabel.backgroundColor = cellLayout?.labelBackgroundColor
        addSubview(underLabel)
    }
    
}






