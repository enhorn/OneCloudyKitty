//
//  ContentView.swift
//  OneExampe
//
//  Created by Robin Enhorn on 2024-11-12.
//

import SwiftUI
import OneCloudyKitty

struct ContentView: View {

    let controller = OneCloudController(database: .public, containerID: "iCloud.SomeTestContainer")
    let subscriber: OneSubscriber<SomeEntity>

    @State var tab: String = "Create"

    init () {
        subscriber = OneSubscriber<SomeEntity>(controller: controller, pullInterval: 5)
        subscriber.start()
    }

    var body: some View {
        TabView {
            CreateEntityView(controller: controller, subscriber: subscriber)
                .tabItem {
                    VStack {
                        Image(systemName: "plus")
                        Text("Create")
                    }
                }
            EntitiesList(subscriber: subscriber)
                .tabItem {
                    VStack {
                        Image(systemName: "list.bullet")
                        Text("Entities (\(subscriber.entities.count))")
                    }
                }
        }
    }

}

extension NSPredicate: @retroactive @unchecked Sendable { }

#Preview {
    ContentView()
}
