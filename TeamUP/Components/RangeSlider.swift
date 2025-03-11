import SwiftUI

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    
    init(range: Binding<ClosedRange<Double>>, in bounds: ClosedRange<Double>) {
        self._range = range
        self.bounds = bounds
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color(red: 0.9, green: 0.3, blue: 0.2))
                    .frame(width: CGFloat((range.upperBound - range.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width,
                           height: 4)
                    .offset(x: CGFloat((range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .frame(width: 24, height: 24)
                        .offset(x: CGFloat((range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = bounds.lowerBound + Double(value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                    if newValue < range.upperBound {
                                        range = newValue...range.upperBound
                                    }
                                }
                        )
                    
                    Circle()
                        .fill(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .frame(width: 24, height: 24)
                        .offset(x: CGFloat((range.upperBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 24)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = bounds.lowerBound + Double(value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                    if newValue > range.lowerBound {
                                        range = range.lowerBound...newValue
                                    }
                                }
                        )
                }
            }
        }
        .frame(height: 24)
    }
} 