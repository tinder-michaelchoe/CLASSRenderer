import ArgumentParser

@main
struct ComponentGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clads-component-generator",
        abstract: "Generate boilerplate code for new component types"
    )
    
    func run() throws {
        print("Component Generator - Coming soon!")
    }
}
