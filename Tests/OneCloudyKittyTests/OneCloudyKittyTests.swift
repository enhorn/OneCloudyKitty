import Testing
import OneCloudyKitty

@Test func creatingEntity() async throws {
    let controller = OneCloudController(database: .public, containerID: "iCloud.SomeTestContainer")

    let entity = try await controller.create(entity: TestEntity(name: "Some Name", age: 37))

    try await controller.delete(entity: entity) // Cleanup
}
