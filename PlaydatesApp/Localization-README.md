# Playdates App Localization Guide

This document explains how localization is implemented in the Playdates app.

## Overview

The app uses a component-based localization approach where:

1. All user-facing strings are extracted to localization files
2. Components use these localized strings rather than hardcoded text
3. Date and time formatting respects the user's locale
4. Multiple languages are supported (currently English and Spanish)

## Localization Structure

- `LocalizationHelpers.swift`: Contains extensions and constants for localization
- `en.lproj/Localizable.strings`: English translations
- `es.lproj/Localizable.strings`: Spanish translations

## How to Use Localization

### Basic String Localization

```swift
// Instead of:
Text("Hello World")

// Use:
Text("hello.world".localized)
// OR
Text.localized("hello.world")
```

### String with Format Arguments

```swift
// Instead of:
Text("\(count) items")

// Use:
Text.localized("items.count", with: count)
```

### Using Localization Constants

We use a structured approach with the `L10n` namespace:

```swift
// Instead of:
Text("hello.world".localized)

// Use:
Text.localized(L10n.SectionName.keyName)
```

## Adding a New Localized String

1. Add the key to the appropriate section in `L10n` struct in `LocalizationHelpers.swift`:

```swift
struct L10n {
    struct NewSection {
        static let newKey = "new.section.key"
    }
}
```

2. Add translations to all Localizable.strings files:

```
// en.lproj/Localizable.strings
"new.section.key" = "Your English text";

// es.lproj/Localizable.strings
"new.section.key" = "Your Spanish text";
```

3. Use in your UI components:

```swift
Text.localized(L10n.NewSection.newKey)
```

## Adding a New Language

1. Create a new folder named `[language-code].lproj` (e.g., `fr.lproj` for French)
2. Copy the `Localizable.strings` file from an existing language
3. Translate all strings
4. Add the language code to `CFBundleLocalizations` array in Info.plist

## Date Formatting

Always use locale-aware date formatting:

```swift
let dateFormatter = DateFormatter()
dateFormatter.dateStyle = .medium
dateFormatter.timeStyle = .short
dateFormatter.locale = Locale.current
return dateFormatter.string(from: date)
```

## Best Practices

1. Never hardcode user-facing strings
2. Group related strings under the same section in `L10n`
3. Use descriptive key names
4. Always include all translations for all supported languages
5. Add comments in the strings files for context when necessary
