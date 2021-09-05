# Mela Recipe Parser

This is a simple Swift package to parse exported recipe files (of type `.melarecipe` and `.melarecipes`) from the iOS recipe app [Mela](https://mela.recipes).

```swift
import MelaRecipeParser

let recipesContainer = try Recipes(fromFilePath: "./Recipes.melarecipes")

switch recipesContainer {
case .melarecipe(let recipe): print(recipe)
case .melarecipes(let recipes): print(recipes)
}

recipesContainer.writeJSON(to: "../Desktop")
recipesContainer.writeMela(to: "../Desktop")
```