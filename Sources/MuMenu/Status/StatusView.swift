// created by musesum on 12/22/23

import SwiftUI

struct StatusView: View {

    var statusVm = StatusVm.shared

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.black)
                .opacity(0.5)
            HStack {
                Text(statusVm.beforeStr)
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .foregroundColor(.white)
                Text(statusVm.afterStr)
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .foregroundColor(.gray)
            }
        }
        .opacity(statusVm.show ? 1 : 0)
    }
}

