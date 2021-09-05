import Foundation
import ZIPFoundation

public struct Recipe: Codable {
    /**
     * The unique ID of the recipe.
     *
     * If `link` is a URL, then ID is `link` without the protocol at the beginning.
     *
     * If `link` is not a URL, then ID is a UUID.
     */
    public var id: String
    public var date: Date
    public var images: [String]
    public var title: String?
    public var yield: String?
    public var cookTime: String?
    public var prepTime: String?
    public var totalTime: String?
    /// AKA "source"; could be a URL or plain text
    public var link: String?
    public var text: String?
    public var ingredients: String?
    public var instructions: String?
    public var notes: String?
    public var nutrition: String?
    /// An array of tags
    public var categories: [String]
    public var wantToCook: Bool
    public var favorite: Bool
}

public enum Recipes {
    case melarecipe(Recipe)
    case melarecipes([Recipe])
        
    /**
     * Reads a `Recipe` object from a .melarecipe or .melarecipes file.
     *
     * - Parameter filePath: Path to a local '.melarecipe' or '.melarecipes' file.
     *
     * - Returns: Returns a `Recipe.melarecipe(Recipe)` if a '.melarecipe' file path
     *            is passed in or a `Recipe.melarecipes([Recipe])` if a '.melarecipes'
     *            file path is passed in.
     *
     * - Throws: `Recipes.Error.incompatibleFormat` if the file path does not point
     *            to a '.melarecipes' or '.melarecipe' file.
     */
    public init(fromFilePath filePath: String) throws {
        switch FileManager.default.pathExtension(filePath) {
        case "melarecipes": self = .melarecipes(try Recipes.readFromZip(filePath: filePath))
        case "melarecipe": self = .melarecipe(try Recipes.readFromJSON(filePath: filePath))
        default: throw Error.incompatibleFormat
        }
    }
    
    /**
     * Writes the `Recipe` or `[Recipe]` contained by `self` to a new JSON file in the specified directory.
     *
     * - Parameter directoryPath: Path to the directory where the file will be written.
     */
    public func writeJSON(to directoryPath: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        var destination = URL(fileURLWithPath: directoryPath)
        
        switch self {
        case .melarecipe(let recipe):
            destination = destination.appendingPathComponent("\(recipe.title ?? recipe.id).json")
        case .melarecipes(_):
            destination = destination.appendingPathComponent("Recipes.json")
        }
        
        try data.write(to: destination)
    }
    
    /**
     * Writes the `Recipe` or `[Recipe]` contained by `self` to a new '.melarecipe' or '.melarecipes' file in the specified directory.
     *
     * - Parameter directoryPath: Path to the directory where the file will be written.
     */
    public func writeMela(to directoryPath: String) throws {
        switch self {
        case .melarecipe(let recipe): try Recipes.write(melaJSON: recipe, to: URL(fileURLWithPath: directoryPath))
        case .melarecipes(let recipes): try Recipes.write(melaZip: recipes, to: directoryPath)
        }
    }
}

extension Recipes: Encodable {
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .melarecipe(let recipe): try recipe.encode(to: encoder)
        case .melarecipes(let recipes): try recipes.encode(to: encoder)
        }
    }
}

extension Recipes {
    public enum Error: LocalizedError {
        /// File must be format '.melarecipes' or '.melarecipe'
        case incompatibleFormat
        /**
         * If `Recipe#link` is a URL, then ID must be `Recipe#link` without the protocol at the beginning.
         *
         * If `Recipe#link` is not a URL, then ID must be a UUID.
         */
        case incorrectIDFormat
        
        public var errorDescription: String {
            switch self {
            case .incompatibleFormat:
                return NSLocalizedString(
                    "File must be format '.melarecipes' or '.melarecipe'",
                    comment: "Recipes.Error.incompatibleFormat"
                )
            case .incorrectIDFormat:
                return NSLocalizedString(
                    "`id` must be equal to `link` if link is present and a URL, otherwise `id` must be a UUID",
                    comment: "Recipes.Error.incorrectIDFormat"
                )
            }
        }
    }
}

extension Recipes {
    private static func readFromZip(filePath: String) throws -> [Recipe] {
        let file = URL(fileURLWithPath: filePath)
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        try FileManager.default.unzipItem(at: file, to: temporaryDirectory)
        
        var recipes: [Recipe] = []
        
        for file in try FileManager.default.contentsOfDirectory(atPath: temporaryDirectory.path) {
            if FileManager.default.isDirectory(file) { continue }
            let recipe = try readFromJSON(filePath: file)
            recipes.append(recipe)
        }
        
        try FileManager.default.removeItem(at: temporaryDirectory)
        return recipes
    }

    private static func readFromJSON(filePath: String) throws -> Recipe {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Recipe.self, from: data)
    }
    
    private static func write(melaJSON recipe: Recipe, to directoryPath: URL) throws {
        if let link = recipe.link, let _ = URL(string: link) {
            guard recipe.id == link else { throw Error.incompatibleFormat }
        } else {
            let pattern = #"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"#
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(recipe.id.startIndex..., in: recipe.id)
            let results = regex.numberOfMatches(in: recipe.id, options: [], range: range)
            guard results > 0 else { throw Error.incompatibleFormat }
        }
        
        let destination = directoryPath.appendingPathComponent("\(recipe.title ?? recipe.id).melarecipe")
        let data = try JSONEncoder().encode(recipe)
        try data.write(to: destination)
    }
    
    private static func write(melaZip recipes: [Recipe], to directoryPath: String) throws {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        for recipe in recipes { try write(melaJSON: recipe, to: temporaryDirectory) }
        let destination = URL(fileURLWithPath: directoryPath).appendingPathComponent("Recipes.melarecipes")
        try FileManager.default.zipItem(at: temporaryDirectory, to: destination)
        try FileManager.default.removeItem(at: temporaryDirectory)
    }
}
