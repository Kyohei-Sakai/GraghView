//
//  GraghView.swift
//  GraghView
//
//  Created by 酒井恭平 on 2016/11/27.
//  Copyright © 2016年 酒井恭平. All rights reserved.
//

import UIKit

// MARK: - Enumeration

enum GraghStyle {
    case bar, round, jaggy
}

enum GraghViewDateStyle {
    case year, month, day, hour, minute, second
}

enum GraghViewDataType {
    case normal, yen
}

enum GraghViewContetOffset {
    case minimumDate, maximizeDate
}

enum GraghViewDataLabelType {
    case `default`, date
}


// MARK: - GraghView Class

class GraghView: UIScrollView {
    
    // MARK: - Private properties
    
    private let roundPathView = UIView()
    
    // MARK: Setting ComparisonValue
    private let comparisonValueLabel = UILabel()
    private let comparisonValueLineView = UIView()
    private let comparisonValueX: CGFloat = 0
    private var comparisonValueY: CGFloat?
    
    // MARK: Setting Average Value
    private let averageLabel = UILabel()
    private let averageLineView = UIView()
    private let averageValueX: CGFloat = 0
    private var averageValueY: CGFloat?
    
    
    // MARK: - Public properties
    
    var graghViewCells: [GraghViewCell] = []
    
    // データ配列
    var graghValues: [CGFloat] = []
    // グラフのラベルに表示する情報
    var graghLabels: [String] = []
    var minimumDate: Date?
    
    
    // garghの種類
    var graghStyle: GraghStyle = .bar
    // under labelに表示するDate間隔
    var dateStyle: GraghViewDateStyle = .month
    // over labelに表示する値の属性
    var dataType: GraghViewDataType = .normal
    // グラフの前から表示するか、後ろからか
    var contentOffsetControll: GraghViewContetOffset = .minimumDate
    // under labelを生成する際に参照する情報
    var dataLabelType:GraghViewDataLabelType = .default
    
    
    // layoutに関するデータのまとまり(struct)
    var cellLayout = CellLayoutOptions()
    var graghLayout = LayoutOptions()
    
    
    // データの中の最大値 -> これをもとにBar表示領域の高さを決める
    var maxGraghValue: CGFloat? { return graghValues.max() }
    // under label のdate間隔 default is 1
    var dateInterval: Int = 1 {
        willSet {
            if newValue < 1 { return }
        }
    }
    
    
    // MARK: Setting ComparisonValue
    
    @IBInspectable var comparisonValue: CGFloat = 0
    
    @IBInspectable var comparisonValueIsHidden: Bool = false {
        didSet {
            comparisonValueLabel.isHidden = comparisonValueIsHidden
            comparisonValueLineView.isHidden = comparisonValueIsHidden
        }
    }
    
    // MARK: Setting Average Value
    var averageValue: CGFloat? {
        return graghValues.reduce(0, +) / CGFloat(graghValues.count)
    }
    
    @IBInspectable var averageValueIsHidden: Bool = false {
        didSet {
            averageLabel.isHidden = averageValueIsHidden
            averageLineView.isHidden = averageValueIsHidden
        }
    }
    
    
    // Delegate
//    var barDelegate: BarGraghViewDelegate?
    
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, graghValues: [CGFloat], minimumDate: Date, style: GraghStyle = .bar) {
        self.init(frame: frame)
        self.graghValues = graghValues
        self.minimumDate = minimumDate
        self.graghStyle = style
        loadGraghView()
    }
    
    // storyboardで生成する時
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - Override
    
    override var contentOffset: CGPoint {
        didSet {
            if !comparisonValueIsHidden {
                // ComparisonValueLabelをスクロールとともに追従させる
                comparisonValueLabel.frame.origin.x = contentOffset.x
            }
        }
    }
    
    
    // MARK: - Private methods
    
    private func dateToMinimumDate(addComponentValue index: Int) -> DateComponents {
        let componentValue = index * dateInterval
        switch dateStyle {
        case .year: return DateComponents(year: componentValue)
        case .month: return DateComponents(month: componentValue)
        case .day: return DateComponents(day: componentValue)
        case .hour: return DateComponents(hour: componentValue)
        case .minute: return DateComponents(minute: componentValue)
        case .second: return DateComponents(second: componentValue)
        }
    }
    
    // MARK: Drawing
    
    // MARK: Comparison Value
    
    private func drawComparisonValue() {
        guard let comparisonValueY = comparisonValueY else { return }
        
        drawComparisonValueLine(from: CGPoint(x: comparisonValueX, y: comparisonValueY), to: CGPoint(x: contentSize.width, y: comparisonValueY))
        
        drawComparisonValueLabel(frame: CGRect(x: comparisonValueX, y: comparisonValueY, width: 50, height: 20), text: overTextFormatter(from: comparisonValue))
    }
    
    private func drawComparisonValueLine(from statPoint: CGPoint, to endPoint: CGPoint) {
        // GraghViewと同じ大きさのViewを用意
        comparisonValueLineView.frame = CGRect(origin: .zero, size: contentSize)
        comparisonValueLineView.backgroundColor = UIColor.clear
        // Lineを描画
        UIGraphicsBeginImageContextWithOptions(contentSize, false, 0)
        let linePath = UIBezierPath()
        linePath.lineCapStyle = .round
        linePath.move(to: statPoint)
        linePath.addLine(to: endPoint)
        linePath.lineWidth = graghLayout.comparisonLineWidth
        graghLayout.comparisonLineColor.setStroke()
        linePath.stroke()
        comparisonValueLineView.layer.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        // GraghViewに重ねる
        addSubview(comparisonValueLineView)
    }
    
    private func drawComparisonValueLabel(frame: CGRect, text: String) {
        comparisonValueLabel.frame = frame
        comparisonValueLabel.text = text
        comparisonValueLabel.textAlignment = .center
        comparisonValueLabel.font = comparisonValueLabel.font.withSize(10)
        comparisonValueLabel.backgroundColor = graghLayout.comparisonLabelBackgroundColor
        addSubview(comparisonValueLabel)
    }
    
    // over Label's text format
    private func overTextFormatter(from value: CGFloat) -> String {
        switch dataType {
        case .normal: return String(describing: value)
        case .yen: return String("\(Int(value)) 円")
        }
    }
    
    // MARK: Round Path
    
    func drawPathToRound() {
        if graghStyle != .round { return }
        
        guard let firstCell = graghViewCells.first, let startPoint = firstCell.endPoint else { return }
        
        // GraghViewと同じ大きさのViewを用意
        roundPathView.frame = CGRect(origin: .zero, size: contentSize)
        roundPathView.backgroundColor = UIColor.clear
        UIGraphicsBeginImageContextWithOptions(contentSize, false, 0)
        // Lineを描画
        let path = UIBezierPath()
        path.move(to: startPoint)
        for index in 1..<graghViewCells.count {
            if let endPoint = graghViewCells[index].endPoint {
                path.addLine(to: CGPoint(x: endPoint.x + CGFloat(index) * cellLayout.cellAreaWidth, y: endPoint.y))
            }
        }
        path.lineWidth = graghLayout.roundPathWidth
        cellLayout.roundColor.setStroke()
        path.stroke()
        roundPathView.layer.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        // GraghViewに重ねる
        addSubview(roundPathView)
    }
    
    // MARK: Average Value
    
    private func drawAverageValue() {
        guard let averageValueY = averageValueY, let averageValue = averageValue else { return }
        
        drawAverageValueLine(from: CGPoint(x: averageValueX, y: averageValueY), to: CGPoint(x: contentSize.width, y: averageValueY))
        
        drawAverageValueLabel(frame: CGRect(x: averageValueX, y: averageValueY, width: 50, height: 20), text: overTextFormatter(from: averageValue))
    }
    
    private func drawAverageValueLine(from statPoint: CGPoint, to endPoint: CGPoint) {
        // GraghViewと同じ大きさのViewを用意
        averageLineView.frame = CGRect(origin: .zero, size: contentSize)
        averageLineView.backgroundColor = UIColor.clear
        // Lineを描画
        UIGraphicsBeginImageContextWithOptions(contentSize, false, 0)
        let linePath = UIBezierPath()
        linePath.lineCapStyle = .round
        linePath.move(to: statPoint)
        linePath.addLine(to: endPoint)
        linePath.lineWidth = graghLayout.averageLineWidth
        graghLayout.averageLineColor.setStroke()
        linePath.stroke()
        averageLineView.layer.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        // GraghViewに重ねる
        addSubview(averageLineView)
    }
    
    private func drawAverageValueLabel(frame: CGRect, text: String) {
        averageLabel.frame = frame
        averageLabel.text = text
        averageLabel.textAlignment = .center
        averageLabel.font = comparisonValueLabel.font.withSize(10)
        averageLabel.backgroundColor = graghLayout.comparisonLabelBackgroundColor
        addSubview(averageLabel)
    }
    
    
    // MARK: - Public methods
    
    func loadGraghView() {
        
        switch dataLabelType {
        case .default: drawCellsOfTextLabel()
        case .date: drawCellsOfDateLabel()
        }
        
        drawPathToRound()
        drawComparisonValue()
        drawAverageValue()
        
        contentOffset.x = {
            switch contentOffsetControll {
            case .minimumDate: return 0
            case .maximizeDate: return contentSize.width - frame.width
            }
        }()
        
    }
    
    private func drawCellsOfTextLabel() {
        for index in 0..<graghValues.count {
            contentSize.width += cellLayout.cellAreaWidth
            // barの表示をずらしていく
            let rect = CGRect(origin: CGPoint(x: CGFloat(index) * cellLayout.cellAreaWidth, y: 0), size: CGSize(width: cellLayout.cellAreaWidth, height: frame.height))
            
            let cell = GraghViewCell(frame: rect, graghValue: graghValues[index], labelText: graghLabels[index], comparisonValue: comparisonValue, target: self)
            
            addSubview(cell)
            
            self.comparisonValueY = cell.comparisonValueY
            self.averageValueY = cell.getEndPointForStartPoint(value: averageValue)
        }
        
    }
    
    private func drawCellsOfDateLabel() {
        let calendar = Calendar(identifier: .gregorian)
        contentSize.height = frame.height
        
        for index in 0..<graghValues.count {
            contentSize.width += cellLayout.cellAreaWidth
            
            if let minimumDate = minimumDate, let date = calendar.date(byAdding: dateToMinimumDate(addComponentValue: index), to: minimumDate) {
                // barの表示をずらしていく
                let rect = CGRect(origin: CGPoint(x: CGFloat(index) * cellLayout.cellAreaWidth, y: 0), size: CGSize(width: cellLayout.cellAreaWidth, height: frame.height))
                
                let cell = GraghViewCell(frame: rect, graghValue: graghValues[index], date: date, comparisonValue: comparisonValue, target: self)
                
                addSubview(cell)
                
                self.comparisonValueY = cell.comparisonValueY
                self.averageValueY = cell.getEndPointForStartPoint(value: averageValue)
            }
        }
    }
    
    func reloadGraghView() {
        // GraghViewの初期化
        subviews.forEach { $0.removeFromSuperview() }
        contentSize = .zero
        
        loadGraghView()
    }
    
    // MARK: Set Gragh Customize Options
    
    func setComparisonValueLabel(backgroundColor: UIColor) {
        graghLayout.comparisonLabelBackgroundColor = backgroundColor
    }
    
    func setComparisonValueLine(color: UIColor) {
        graghLayout.comparisonLineColor = color
    }
    
    // BarのLayoutProportionはGraghViewから変更する
    func setCellArea(width: CGFloat) {
        cellLayout.cellAreaWidth = width
    }
    
    func setBarAreaHeight(rate: CGFloat) {
        cellLayout.barAreaHeightRate = rate
    }
    
    func setMaxGraghValue(rate: CGFloat) {
        cellLayout.maxGraghValueRate = rate
    }
    
    func setBarWidth(rate: CGFloat) {
        cellLayout.barWidthRate = rate
    }
    
    func setBar(color: UIColor) {
        cellLayout.barColor = color
    }
    
    func setLabel(backgroundcolor: UIColor) {
        cellLayout.labelBackgroundColor = backgroundcolor
    }
    
    func setGragh(backgroundcolor: UIColor) {
        cellLayout.GraghBackgroundColor = backgroundcolor
    }
    
    func setRoundSize(rate: CGFloat) {
        cellLayout.roundSizeRate = rate
    }
    
    func setRound(color: UIColor) {
        cellLayout.roundColor = color
    }
    
    func setRoundIsHidden(bool: Bool) {
        cellLayout.onlyPathLine = bool
    }
    
    func setValueLabelIsHidden(bool: Bool) {
        cellLayout.valueLabelIsHidden = bool
    }
    
    
    // MARK: - Struct
    
    // GraghViewCellのレイアウトを決定するためのデータ
    struct CellLayoutOptions {
        // MARK: Shared
        
        // cellAreaHeight / frame.height
        var barAreaHeightRate: CGFloat = 0.8
        // maxGraghValueRate / maxBarAreaHeight
        var maxGraghValueRate: CGFloat = 0.8
        // cell width
        var cellAreaWidth: CGFloat = 50
        // if over label is hidden
        var valueLabelIsHidden: Bool = false
        
        // MARK: Only Bar
        
        // bar.width / rect.width
        var barWidthRate: CGFloat = 0.5
        // Bar Color
        var barColor = UIColor.init(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
        // Label backgroundColor
        var labelBackgroundColor = UIColor.init(white: 0.95, alpha: 1.0)
        // Gragh backgroundColor
        var GraghBackgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
        
        // MARK: Only Round
        
        // round size / cellAreaWidth
        var roundSizeRate: CGFloat = 0.1
        // round color
        var roundColor = UIColor.init(red: 0.7, green: 0.7, blue: 1.0, alpha: 1.0)
        // if round is hidden
        var onlyPathLine: Bool = false
        
        // MARK: Only Jaggy
        
        // jaggy color
        var jaggyColor = UIColor.init(red: 1.0, green: 1.0, blue: 0.6, alpha: 1.0)
        
        
    }
    
    // GraghViewCellsに付加するViewsのレイアウトを決定するためのデータ
    struct LayoutOptions {
        // MARK: Comparison Value
        
        var comparisonLabelBackgroundColor = UIColor.lightGray.withAlphaComponent(0.7)
        var comparisonLineColor = UIColor.red
        var comparisonLineWidth: CGFloat = 1
        
        // MARK: Round Path
        
        var roundPathWidth: CGFloat = 2
        
        // MARK: Average Value
        var avarageLabelBackgroundColor = UIColor.init(red: 0.8, green: 0.7, blue: 1, alpha: 0.7)
        var averageLineColor = UIColor.init(red: 0.7, green: 0.6, blue: 0.9, alpha: 1)
        var averageLineWidth: CGFloat = 1
        
        
    }
    
}
