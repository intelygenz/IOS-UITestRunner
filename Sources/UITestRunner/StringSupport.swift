import Foundation

private let camelCaseifyAllowedChars = CharacterSet(characters: "a"..."z", "A"..."Z", "0"..."9").union(camelCaseifySeparators)
private let camelCaseifySeparators = CharacterSet(characters: " ", "-")
private let camelCaseifyDisallowedChars = camelCaseifyAllowedChars.inverted

extension String {
    
    var methodCamelCase: String { camelCaseify.lowercaseFirstLetterString }
    
    var classCamelCase: String { camelCaseify.uppercaseFirstLetterString }
    
    var camelCaseify: String {
        replacingCharacters(fromSet: camelCaseifyDisallowedChars)
            .components(separatedBy: camelCaseifySeparators)
            .map { $0.uppercaseFirstLetterString }
            .joined(separator: "")
    }

    var uppercaseFirstLetterString: String {
        guard let firstCharacter = self.first else { return self }
        return String(firstCharacter).uppercased() + String(self.dropFirst())
    }
    
    var lowercaseFirstLetterString: String {
        guard let firstCharacter = self.first else { return self }
        return String(firstCharacter).lowercased() + String(self.dropFirst())
    }
    
    var humanReadableString: String {
        guard self.count > 1, let firstCharacter = self.first else { return self }
        return String(firstCharacter) + self.dropFirst().reduce("") { (word, character) in
            let letter = String(character)
            return letter == letter.uppercased() ? "\(word) \(letter)" : "\(word)\(letter)"
        }
    }
    
}

private extension String {
        
    func replacingCharacters(fromSet characterSet: CharacterSet, with replacementString: String = "") -> String {
        return components(separatedBy: characterSet).joined(separator: replacementString)
    }
}


private extension CharacterSet {
    init(characters: CharacterSetMember...) {
        self.init()
        characters.forEach {
            if let closedRange = $0 as? ClosedRange<Unicode.Scalar> {
                insert(charactersIn: closedRange)
            } else if let character = $0 as? Unicode.Scalar {
                insert(character)
            } else if let string = $0 as? String {
                insert(charactersIn: string)
            }
        }
    }
}

private protocol CharacterSetMember { }
extension ClosedRange: CharacterSetMember where Bound == Unicode.Scalar { }
extension Unicode.Scalar: CharacterSetMember { }
extension String: CharacterSetMember { }
