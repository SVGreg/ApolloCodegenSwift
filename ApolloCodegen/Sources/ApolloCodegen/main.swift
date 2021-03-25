import Foundation
import ApolloCodegenLib
import ArgumentParser

// An outer structure to hold all commands and sub-commands handled by this script.
struct SwiftScript: ParsableCommand {

    static var configuration = CommandConfiguration(
            abstract: """
        A swift-based utility for performing Apollo-related tasks.
        
        NOTE: If running from a compiled binary, prefix subcommands with `swift-script`. Otherwise use `swift run ApolloCodegen [subcommand]`.
        """,
            subcommands: [DownloadSchema.self, GenerateCode.self])
    
    /// The sub-command to download a schema from a provided endpoint.
    struct DownloadSchema: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "downloadSchema",
            abstract: "Downloads the schema with the settings you've set up in the `DownloadSchema` command in `main.swift`.")
        
        @Argument(help: "Folder name where to save GraphQL schema")
        var schemaFolder: String

        @Argument(help: "URL to GraphQL endpoint")
        var apolloURL: String

        func validate() throws {
            guard schemaFolder.count > 0 else {
                throw ValidationError("'<schema-folder>' must not be empty")
            }
            guard apolloURL.count > 0 else {
                throw ValidationError("'<apollo-url>' must not be empty")
            }
        }

        mutating func run() throws {
            let fileStructure = try FileStructure()
            CodegenLogger.log("File structure: \(fileStructure)")
            
            // Set up the URL you want to use to download the project
            let endpoint = URL(string: apolloURL)!
            
            // Calculate where you want to create the folder where the schema will be downloaded by the ApolloCodegenLib framework.
            let folderForDownloadedSchema = fileStructure.sourceRootURL
                .apollo.childFolderURL(folderName: schemaFolder)
            
            // Make sure the folder is created before trying to download something to it.
            try FileManager.default.apollo.createFolderIfNeeded(at: folderForDownloadedSchema)
            
            // Create an options object for downloading the schema. Provided code will download the schema via an introspection query to the provided URL as JSON to a file called "schema.json". For full options check out https://www.apollographql.com/docs/ios/api/ApolloCodegenLib/structs/ApolloSchemaOptions/
            let schemaDownloadOptions = ApolloSchemaOptions(downloadMethod: .introspection(endpointURL: endpoint),
                                                            outputFolderURL: folderForDownloadedSchema)
            
            // Actually attempt to download the schema.
            try ApolloSchemaDownloader.run(with: fileStructure.cliFolderURL,
                                           options: schemaDownloadOptions)
        }
    }
    
    /// The sub-command to actually generate code.
    struct GenerateCode: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "generate",
            abstract: "Generates swift code from your schema + your operations based on information set up in the `GenerateCode` command.")
        
        @Argument(help: "Folder name where GraphQL schema and query files are located")
        var schemaFolder: String

        func validate() throws {
            guard schemaFolder.count > 0 else {
                throw ValidationError("'<schema-folder>' must not be empty")
            }
        }

        mutating func run() throws {
            let fileStructure = try FileStructure()
            CodegenLogger.log("File structure: \(fileStructure)")
            
            // Get the root of the target for which you want to generate code.
            let targetRootURL = fileStructure.sourceRootURL
                .apollo.childFolderURL(folderName: schemaFolder)
            
            // Make sure the folder exists before trying to generate code.
            try FileManager.default.apollo.createFolderIfNeeded(at: targetRootURL)

            // Create the Codegen options object. This default setup assumes `schema.json` is in the target root folder, all queries are in some kind of subfolder of the target folder and will output as a single file to `API.swift` in the target folder. For alternate setup options, check out https://www.apollographql.com/docs/ios/api/ApolloCodegenLib/structs/ApolloCodegenOptions/
            let codegenOptions = ApolloCodegenOptions(targetRootURL: targetRootURL)
            
            // Actually attempt to generate code.
            try ApolloCodegen.run(from: targetRootURL,
                                  with: fileStructure.cliFolderURL,
                                  options: codegenOptions)
        }
    }
}

// This will set up the command and parse the arguments when this executable is run.
SwiftScript.main()
