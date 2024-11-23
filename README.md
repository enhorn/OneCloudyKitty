# OneCloudyKitty
A small package to simplify basic CloudKit interactions, uses Async/Await and pulls data on a configured time interval.

## Usage example

The content this tutorial, with some extras, can be found in the package's Example project.

Before we start set up a CloudKit container and selecting it in your Xcode project. This README doesn't cover that generic CloudKit part.

We start by defining our model that we want to store.
```swift
// Model fulfilling the protocol `OneRecordable`.
final class SomeEntity: OneRecordable {

    var recordID: CKRecord.ID // Required by `OneRecordable`.
    var name: String
    var age: Int

    init(name: String, age: Int) {
        self.recordID = Self.generateID() // Has a default implementation in `OneRecordable`.
        self.name = name
        self.age = age
    }

    // Required by `OneRecordable`. Can return `nil`.
    required init?(_ record: CKRecord) {
        guard let name = record["name"] as? String, let age = record["age"] as? Int else { return nil }
        self.recordID = record.recordID
        self.name = name
        self.age = age
    }

}
```

We can then use the model together with an `OneCloudController`.
```swift
let controller = OneCloudController(database: .public, containerID: "iCloud.SomeTestContainer")

// Interactions with CloudKit will throw when failing.
// So for this example we put everything in a single do/catch.
do {

    // The entity will now be saved to CloudKit.
    let entity = try await controller.create(entity: SomeEntity(name: "Some entity", age: 41))

    // Here we update one of the properties and save the entity.
    // Saving, updating and deleting entities return a `discardable` copy of the entity.
    entity.name = "Saved entity"
    entity = try await controller.save(entity: entity)

    // We can update a single property based on a keypath.
    entity = try await controller.updateProperty(entity: entity, property: \.age, value: 42)

    // We can fetch all entities stored in CloudKit.
    // The `getAll()` function has an optional `NSPredicate` parameter for filtering the result.
    let entities: [SomeEntity] = try await controller.getAll()

    // And we can delete the entity from the CloudKit storage.
    try await controller.delete(entity: entity)

} catch let error {
    print(error)
}
```

Let's define a list that automatically updates it's content based on a subscribed entity type.
```swift
struct EntitiesList: View {

    // The subscriber is `@Observable`.
    let subscriber: OneSubscriber<SomeEntity>

    var body: some View {
        List {
            // The observable subscriber has a published array named `entities`.
            ForEach(subscriber.entities) { entity in
                Text(entity.name)
            }
        }.refreshable {
            do {
                // We can manually trigger a refresh of the entities.
                try await subscriber.refresh()
            } catch let error {
                print(error)
            }
        }
    }

}
```

And now let's display the list in our app.
```swift
struct ContentView: View {

    let controller = OneCloudController(database: .public, containerID: "iCloud.SomeTestContainer")
    let subscriber: OneSubscriber<SomeEntity>

    init () {
        // Takes an optional `NSPredicate` parameter for filtering the fetched entities.
        // Also has an optional time intervall for pulling. Defaults to `5` minutes.
        subscriber = OneSubscriber<SomeEntity>(controller: controller)
        subscriber.start() // Starts pulling data
    }

    var body: some View {
        NavigationStack {
            EntitiesList(subscriber: subscriber)
                .navigationTitle("My subscribed entities")
        }
    }

}
```

There is also a database backed subscriber available, that will keep the database up-to-date with CloudKit.
```swift
OneStoredSubscriber<SomeEntity.StorageModel, SomeEntity>(
    containerURL: URL.documentsDirectory.appendingPathComponent("Test/database.sqlite"),
    controller: OneCloudController(containerID: "iCloud.SomeTestContainer"),
    updateModel: { model, entity in
        model.name = entity.name
        model.age = entity.age
        model.changeDate = entity.changeDate
    },
    updateEntity: { entity, model in
        entity.name = model.name
        entity.age = model.age
        entity.changeDate = model.changeDate
    }
)
```
