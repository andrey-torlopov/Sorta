import SwiftUI

struct DateSelectionView: View {
    @Environment(\.appLocalizer) private var localizer
    @Binding var selectedDate: Date
    @State private var isShowingDatePicker = false

    var body: some View {
        HStack {
            Button {
                isShowingDatePicker.toggle()
            } label: {
                Text(selectedDateFormatted())
                    .defaultButtonStyle()
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 20)
            .frame(maxWidth: 200)
            .popover(isPresented: $isShowingDatePicker, arrowEdge: .bottom) {
                DatePickerPopover(selectedDate: $selectedDate, isShowing: $isShowingDatePicker)
                    .frame(width: 300, height: 250)
            }
        }
    }

    private func selectedDateFormatted() -> String {
        let formatter = DateFormatter()
        formatter.locale = localizer.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: selectedDate)
    }
}

struct DatePickerPopover: View {
    @Environment(\.appLocalizer) private var localizer
    @Binding var selectedDate: Date
    @Binding var isShowing: Bool  // Управляем состоянием popover

    var body: some View {
        VStack {
            DatePicker(localizer("select_date"), selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(FieldDatePickerStyle()) // Удобный стиль для macOS
                .padding()

            Button(localizer("date_picker_done")) {
                isShowing = false // Закрываем popover, изменяя его состояние
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
