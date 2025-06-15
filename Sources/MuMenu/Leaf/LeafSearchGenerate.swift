// created by musesum on 6/13/25
//#if canImport(FoundationModels)
//
//import FoundationModels
//import MuFlo
//
//// Define a struct that mirrors your menu tree
//@available(iOS 26.0, *)
//@Generable
//struct MenuUpdate: Decodable {
//    struct Target: Decodable {
//        let path: String   // e.g. "sky.main.run"
//        let value: Double  // e.g. 0.8
//    }
//    let update: Target
//}
//
//// Tool that reads current values
//@available(iOS 26.0, *)
//struct GetValueTool: Tool {
//    @Generable
//    struct Arguments {
//        var min: Double = 0
//        var max: Double = 1
//        var now: Double = 0
//    }
//    
//    var parameters: GenerationSchema
//    let name = "currentValue"
//    let description = "Returns current scalar value for a menu path"
//    
//    init(parameters: GenerationSchema) {
//        //
//        self.parameters = parameters
//    }
//    
//    func call(arguments: Arguments) async throws -> ToolOutput {
//        return ToolOutput(stub())
//    }
//    func stub() -> String {
//        return ("min 1 max 2 now 1.5")
//    }
//}
//
//// Tool that sets the value
//@available(iOS 26.0, *)
//struct SetValueTool: Tool {
//    var parameters: GenerationSchema
//    let name: String
//    let description: String
//    
//    init(parameters: GenerationSchema) {
//        self.parameters = parameters
//        self.name = "setValue"
//        self.description = "Sets scalar value at menu path"
//    }
//
//    func call(with input: String) -> String {
//        let parts = input.split(separator: "=")
//        guard parts.count == 2,
//              let value = Double(parts[1]) else {
//            return "Invalid input"
//        }
//        let path = String(parts[0])
//        setValue(at: path, to: value)
//        return "OK"
//    }
//    func setValue(at path: String, to: Double) {
//        print("setting path: \(path) to: \(to.digits(2))")
//    }
//}
//
//@available(iOS 26.0, *)
//func processCommand(_ sentence: String) async throws {
//    // Dummy GenerationSchema instance (replace with real schema as needed)
//    let generationSchemaInstance = GenerationSchema(type: <#any Generable.Type#>, properties: <#[GenerationSchema.Property]#>)
//    
//    let prompt = """
//    Receive direct commands to update settings. \
//    Reply with a JSON {\n  "update": { "path": "...", "value": ... }\n}. \
//    Input: "\(sentence)"
//    """
//
//    let session = LanguageModelSession()
//    // Removed session.registerTool calls because they do not exist
//
//    let generated: GeneratedContent<MenuUpdate> = try await session.respond(
//        to: prompt,
//        as: MenuUpdate.self
//    )
//
//    let path = generated.update.path
//    let newValue = generated.update.value
//
//    // Optionally fetch current value with dummy Arguments
//    let current = try await GetValueTool(parameters: generationSchemaInstance).call(arguments: .init())
//    print("Before: \(current)")
//
//    // Apply the change
//    let result = SetValueTool(parameters: generationSchemaInstance).call(with: "\(path)=\(newValue)")
//    print("Set result: \(result)")
//
//    // Removed invalid call to GetValueTool().call(with: path)
//}
//#endif
