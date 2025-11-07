import SwiftUI

struct ContentView: View {
    @State private var display = "0"
    @State private var previousValue: Double?
    @State private var pendingOperator: Operator?
    @State private var isEnteringNewNumber = true
    
    private let buttons: [[CalculatorButton]] = [
        [.function(.clear), .function(.toggleSign), .function(.percent), .operation(.divide)],
        [.digit("7"), .digit("8"), .digit("9"), .operation(.multiply)],
        [.digit("4"), .digit("5"), .digit("6"), .operation(.subtract)],
        [.digit("1"), .digit("2"), .digit("3"), .operation(.add)],
        [.digit("0"), .digit("."), .function(.backspace), .operation(.equals)]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let safeInsets = geometry.safeAreaInsets
            let safeSize = CGSize(width: geometry.size.width,
                                  height: geometry.size.height - safeInsets.top - safeInsets.bottom)
            let spacing = dynamicSpacing(for: safeSize)
            let contentWidth = max(safeSize.width - spacing * 2, 0)
            let columnWidth = columnWidth(for: contentWidth, spacing: spacing)
            let layout = layoutMetrics(for: safeSize,
                                       spacing: spacing,
                                       columnWidth: columnWidth)

            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: spacing) {
                    displayView(height: layout.displayHeight,
                                fontSize: displayFontSize(for: safeSize,
                                                          displayHeight: layout.displayHeight))
                    buttonGrid(columnWidth: columnWidth,
                               buttonHeight: layout.buttonHeight,
                               spacing: spacing,
                               labelSize: labelFontSize(forButtonHeight: layout.buttonHeight,
                                                        columnWidth: columnWidth))
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, safeInsets.top + spacing)
                .padding(.horizontal, spacing)
                .padding(.bottom, safeInsets.bottom + spacing)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private func displayView(height: CGFloat, fontSize: CGFloat) -> some View {
        Text(display)
            .font(.system(size: fontSize, weight: .light))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.25)
            .allowsTightening(true)
            .frame(maxWidth: .infinity, maxHeight: height, alignment: .bottomTrailing)
    }

    private func buttonGrid(columnWidth: CGFloat,
                            buttonHeight: CGFloat,
                            spacing: CGFloat,
                            labelSize: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 4)
        let cornerRadius = buttonHeight / 2

        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(buttons, id: \.self) { row in
                ForEach(row, id: \.self) { button in
                    Button(action: { handleTap(button) }) {
                        Text(button.title)
                            .font(.system(size: labelSize, weight: .medium))
                            .frame(maxWidth: .infinity,
                                   minHeight: buttonHeight,
                                   maxHeight: buttonHeight)
                            .background(button.backgroundColor)
                            .foregroundColor(button.foregroundColor)
                            .cornerRadius(cornerRadius)
                    }
                    .gridCellColumns(gridSpan(for: button))
                }
            }
        }
    }

    private func dynamicSpacing(for size: CGSize) -> CGFloat {
        let base = min(size.width, size.height) * 0.02
        return max(base, 8)
    }

    private func displayFontSize(for size: CGSize, displayHeight: CGFloat) -> CGFloat {
        guard displayHeight > 0 else { return 42 }
        let heightDriven = displayHeight * 0.6
        let widthDriven = size.width * 0.18
        let maxAllowed = size.height * 0.16
        return min(max(min(heightDriven, widthDriven), 42), maxAllowed)
    }

    private func columnWidth(for contentWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        let columns: CGFloat = 4
        let totalSpacing = spacing * (columns - 1)
        let rawWidth = columns > 0 ? (contentWidth - totalSpacing) / columns : 0
        return max(rawWidth, 0)
    }

    private func layoutMetrics(for safeSize: CGSize,
                               spacing: CGFloat,
                               columnWidth: CGFloat) -> (displayHeight: CGFloat, buttonHeight: CGFloat) {
        let rows = CGFloat(buttons.count)
        let minDisplayHeight = max(safeSize.height * 0.18, 110)
        let preferredDisplayHeight = min(max(safeSize.height * 0.25, minDisplayHeight), safeSize.height * 0.35)
        let availableForGrid = max(safeSize.height - preferredDisplayHeight - spacing, 0)
        let verticalSpacingTotal = spacing * (rows - 1)
        let heightLimitedButton = rows > 0 ? (availableForGrid - verticalSpacingTotal) / rows : 0
        let widthLimitedButton = columnWidth * 0.82

        var buttonHeight = min(widthLimitedButton, heightLimitedButton)
        if !buttonHeight.isFinite || buttonHeight <= 0 {
            buttonHeight = widthLimitedButton
        }
        buttonHeight = min(max(buttonHeight, 48), max(widthLimitedButton, 48))

        var gridHeight = buttonHeight * rows + verticalSpacingTotal
        var displayHeight = max(safeSize.height - gridHeight - spacing, minDisplayHeight)

        if displayHeight + gridHeight + spacing > safeSize.height {
            let adjustedAvailableForGrid = max(safeSize.height - minDisplayHeight - spacing, 0)
            let adjustedHeight = rows > 0 ? (adjustedAvailableForGrid - verticalSpacingTotal) / rows : 0
            var fallbackHeight = min(widthLimitedButton, adjustedHeight)
            if !fallbackHeight.isFinite || fallbackHeight <= 0 {
                fallbackHeight = widthLimitedButton
            }
            buttonHeight = min(max(fallbackHeight, 44), max(widthLimitedButton, 44))
            gridHeight = buttonHeight * rows + verticalSpacingTotal
            displayHeight = max(safeSize.height - gridHeight - spacing, minDisplayHeight * 0.8)
        }

        displayHeight = min(displayHeight, safeSize.height * 0.45)
        return (displayHeight, buttonHeight)
    }

    private func labelFontSize(forButtonHeight height: CGFloat, columnWidth: CGFloat) -> CGFloat {
        guard height > 0 else { return max(min(columnWidth * 0.5, 20), 12) }
        let widthLimit = columnWidth * 0.6
        let size = min(height * 0.55, widthLimit)
        return max(size, height * 0.38)
    }

    private func gridSpan(for button: CalculatorButton) -> Int {
        if case .digit("0") = button {
            return 2
        }
        return 1
    }
    
    private func handleTap(_ button: CalculatorButton) {
        switch button {
        case .digit(let value):
            appendDigit(value)
        case .operation(let op):
            handleOperation(op)
        case .function(let fn):
            handleFunction(fn)
        }
    }
    
    private func appendDigit(_ digit: String) {
        if isEnteringNewNumber {
            display = digit == "." ? "0." : digit
            isEnteringNewNumber = digit == "."
        } else {
            if digit == "." && display.contains(".") {
                return
            }
            display += digit
        }
    }
    
    private func handleOperation(_ op: Operator) {
        guard let current = Double(display) else { return }

        switch op {
        case .equals:
            guard let pending = pendingOperator, let previous = previousValue else { return }
            let result = apply(pending, lhs: previous, rhs: current)
            displayResult(result)
            pendingOperator = nil
            previousValue = nil
            isEnteringNewNumber = true
        default:
            if let pending = pendingOperator, let previous = previousValue {
                let result = apply(pending, lhs: previous, rhs: current)
                displayResult(result)
                previousValue = result
            } else {
                previousValue = current
            }
            pendingOperator = op
            isEnteringNewNumber = true
        }
    }

    private func apply(_ op: Operator, lhs: Double, rhs: Double) -> Double {
        switch op {
        case .add:
            return lhs + rhs
        case .subtract:
            return lhs - rhs
        case .multiply:
            return lhs * rhs
        case .divide:
            return rhs == 0 ? Double.nan : lhs / rhs
        case .equals:
            return rhs
        }
    }
    
    private func handleFunction(_ function: CalculatorFunction) {
        switch function {
        case .clear:
            clearAll()
        case .toggleSign:
            toggleSign()
        case .percent:
            convertToPercent()
        case .backspace:
            deleteLastDigit()
        }
    }
    
    private func clearAll() {
        display = "0"
        previousValue = nil
        pendingOperator = nil
        isEnteringNewNumber = true
    }
    
    private func toggleSign() {
        guard let value = Double(display) else { return }
        displayResult(-value)
    }
    
    private func convertToPercent() {
        guard let value = Double(display) else { return }
        if let pending = pendingOperator, pending != .equals, let base = previousValue {
            displayResult(base * value / 100)
        } else {
            displayResult(value / 100)
        }
        isEnteringNewNumber = true
    }
    
    private func deleteLastDigit() {
        guard !isEnteringNewNumber else { return }
        display.removeLast()
        if display.isEmpty || display == "-" {
            display = "0"
            isEnteringNewNumber = true
        }
    }
    
    private func displayResult(_ value: Double) {
        if value.isNaN || value.isInfinite {
            display = "Error"
        } else if value.truncatingRemainder(dividingBy: 1) == 0 {
            display = String(format: "%.0f", value)
        } else {
            display = String(value)
        }
    }
}

// MARK: - Models & Helpers

enum CalculatorButton: Hashable {
    case digit(String)
    case operation(Operator)
    case function(CalculatorFunction)
    
    var title: String {
        switch self {
        case .digit(let value):
            return value
        case .operation(let op):
            return op.symbol
        case .function(let fn):
            return fn.symbol
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .operation:
            return Color.red
        case .function:
            return Color(.lightGray)
        case .digit:
            return Color(.darkGray)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .function:
            return .black
        default:
            return .white
        }
    }
}

enum Operator: Hashable {
    case add, subtract, multiply, divide, equals
    
    var symbol: String {
        switch self {
        case .add: return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide: return "÷"
        case .equals: return "="
        }
    }
}

enum CalculatorFunction: Hashable {
    case clear, toggleSign, percent, backspace
    
    var symbol: String {
        switch self {
        case .clear: return "AC"
        case .toggleSign: return "±"
        case .percent: return "%"
        case .backspace: return "⌫"
        }
    }
}
