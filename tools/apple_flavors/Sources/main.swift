import Foundation
import PathKit
import XcodeProj

// Use XcodeProj's object model rather than editing serialized project text.
let root = Path(CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath).absolute()
let settingsOnly = CommandLine.arguments.contains("--settings-only")

func requireObjC(_ config: XCBuildConfiguration) {
    if var flags = config.buildSettings["OTHER_LDFLAGS"] as? [String] {
        if !flags.contains("-ObjC") { flags.append("-ObjC") }
        config.buildSettings["OTHER_LDFLAGS"] = flags
    } else {
        let flags = config.buildSettings["OTHER_LDFLAGS"] as? String ?? "$(inherited)"
        config.buildSettings["OTHER_LDFLAGS"] = flags.contains("-ObjC") ? flags : flags + " -ObjC"
    }
}

func updatePlist(_ path: Path, values: [String: Any]) throws {
    let data = try Data(contentsOf: URL(fileURLWithPath: path.string))
    var plist = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
    for (key, value) in values { plist[key] = value }
    try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        .write(to: URL(fileURLWithPath: path.string))
}

for platform in ["ios", "macos"] {
    let nativeRoot = root + platform
    let projectPath = nativeRoot + "Runner.xcodeproj"
    let project = try XcodeProj(path: projectPath)
    let pbx = project.pbxproj
    guard let runner = pbx.nativeTargets.first(where: { $0.name == "Runner" }),
          let mainGroup = try pbx.rootProject()?.mainGroup else {
        fatalError("Runner target/main group missing in \(platform)")
    }

    if settingsOnly {
        for config in runner.buildConfigurationList?.buildConfigurations ?? [] { requireObjC(config) }
        if platform == "macos" {
            for mode in ["Debug", "Profile", "Release"] {
                for environment in ["dev", "prod"] {
                    let path = nativeRoot + "Runner/Configs/\(mode)-\(environment).xcconfig"
                    let contents = try String(contentsOfFile: path.string, encoding: .utf8)
                    if !contents.contains("AppInfo.xcconfig") {
                        try ("#include \"AppInfo.xcconfig\"\n" + contents).write(toFile: path.string, atomically: true, encoding: .utf8)
                    }
                }
            }
        }
        try project.writePBXProj(path: projectPath, outputSettings: PBXOutputSettings())
        continue
    }

    let lists = pbx.projects.compactMap { $0.buildConfigurationList } + pbx.nativeTargets.compactMap { $0.buildConfigurationList }
    for list in lists {
        for mode in ["Debug", "Profile", "Release"] {
            guard let original = list.buildConfigurations.first(where: { $0.name == mode }) else { continue }
            for environment in ["dev", "prod"] {
                let name = "\(mode)-\(environment)"
                let config: XCBuildConfiguration
                if let existing = list.buildConfigurations.first(where: { $0.name == name }) {
                    config = existing
                } else {
                    config = XCBuildConfiguration(name: name, baseConfiguration: original.baseConfiguration, buildSettings: original.buildSettings)
                    pbx.add(object: config)
                    list.buildConfigurations.append(config)
                }
                config.buildSettings["FIREBASE_ENV"] = environment
                if list === runner.buildConfigurationList {
                    requireObjC(config)
                    config.buildSettings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.bramwell.bramwellsPrecisionTestKit" + (environment == "dev" ? ".dev" : "")
                    config.buildSettings["APP_DISPLAY_NAME"] = environment == "dev" ? "Precision Test Kit Dev" : "Precision Test Kit"
                    config.buildSettings["ENABLE_USER_SCRIPT_SANDBOXING"] = "NO"
                    config.buildSettings["INFOPLIST_FILE"] = environment == "dev" ? "Runner/Info-dev.plist" : "Runner/Info.plist"
                    if platform == "macos" && environment == "dev" {
                        config.buildSettings["PRODUCT_NAME"] = "bramwells_precision_test_kit_dev"
                    }
                    let relative = platform == "ios" ? "Flutter/\(name).xcconfig" : "Runner/Configs/\(name).xcconfig"
                    let wrapper = nativeRoot + relative
                    let podsMode = mode.lowercased()
                    let content = platform == "ios"
                        ? "#include? \"Pods/Target Support Files/Pods-Runner/Pods-Runner.\(podsMode)-\(environment).xcconfig\"\n#include \"Generated.xcconfig\"\n"
                        : "#include \"AppInfo.xcconfig\"\n#include \"\(mode == "Profile" ? "Release" : mode).xcconfig\"\n#include? \"../../Pods/Target Support Files/Pods-Runner/Pods-Runner.\(podsMode)-\(environment).xcconfig\"\n"
                    try content.write(toFile: wrapper.string, atomically: true, encoding: .utf8)
                    let reference: PBXFileReference
                    if let existing = pbx.fileReferences.first(where: { $0.path == relative }) {
                        reference = existing
                    } else {
                        reference = try mainGroup.addFile(at: wrapper, sourceRoot: nativeRoot)
                    }
                    config.baseConfiguration = reference
                } else if pbx.nativeTargets.contains(where: { $0.name == "RunnerTests" && $0.buildConfigurationList === list }) {
                    config.buildSettings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.bramwell.bramwellsPrecisionTestKit" + (environment == "dev" ? ".dev" : "") + ".RunnerTests"
                }
            }
        }
    }

    // A build phase copies exactly one selected plist; never bundle the old default.
    for phase in runner.buildPhases.compactMap({ $0 as? PBXResourcesBuildPhase }) {
        phase.files?.removeAll { ($0.file?.path ?? "").hasSuffix("GoogleService-Info.plist") }
    }
    for group in pbx.groups {
        group.children.removeAll { ($0 as? PBXFileReference)?.path?.hasSuffix("GoogleService-Info.plist") == true }
    }
    let phaseName = "Select Firebase environment"
    let phase: PBXShellScriptBuildPhase
    if let existing = runner.buildPhases.compactMap({ $0 as? PBXShellScriptBuildPhase }).first(where: { $0.name == phaseName }) {
        phase = existing
    } else {
        phase = PBXShellScriptBuildPhase(name: phaseName, shellPath: "/bin/sh", shellScript: "")
        pbx.add(object: phase)
        runner.buildPhases.append(phase)
    }
    phase.shellScript = "sh \"$SRCROOT/../scripts/select_firebase_apple.sh\"\n"
    phase.inputPaths = ["$(SRCROOT)/Firebase/$(FIREBASE_ENV)/GoogleService-Info.plist", "$(SRCROOT)/../scripts/select_firebase_apple.sh"]
    phase.outputPaths = ["$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist"]
    try project.write(path: projectPath)

    let schemeDirectory = projectPath + "xcshareddata/xcschemes"
    let schemeSource = try Data(contentsOf: URL(fileURLWithPath: (schemeDirectory + "Runner.xcscheme").string))
    for environment in ["dev", "prod"] {
        let document = try XMLDocument(data: schemeSource)
        for (element, mode) in [("TestAction", "Debug"), ("LaunchAction", "Debug"), ("AnalyzeAction", "Debug"), ("ProfileAction", "Profile"), ("ArchiveAction", "Release")] {
            for node in try document.nodes(forXPath: "//\(element)") {
                (node as? XMLElement)?.attribute(forName: "buildConfiguration")?.stringValue = "\(mode)-\(environment)"
            }
        }
        if platform == "macos" && environment == "dev" {
            for node in try document.nodes(forXPath: "//BuildableReference[@BlueprintName='Runner']") {
                (node as? XMLElement)?.attribute(forName: "BuildableName")?.stringValue = "bramwells_precision_test_kit_dev.app"
            }
        }
        try document.xmlData(options: [.nodePrettyPrint]).write(to: URL(fileURLWithPath: (schemeDirectory + "\(environment).xcscheme").string))
    }
    try updatePlist(nativeRoot + "Runner/Info.plist", values: ["CFBundleDisplayName": "$(APP_DISPLAY_NAME)"])
    let info = try Data(contentsOf: URL(fileURLWithPath: (nativeRoot + "Runner/Info.plist").string))
    try info.write(to: URL(fileURLWithPath: (nativeRoot + "Runner/Info-dev.plist").string))
    try updatePlist(nativeRoot + "Runner/Info-dev.plist", values: ["NSAppTransportSecurity": ["NSAllowsArbitraryLoads": true]])
    if platform == "macos" {
        for file in ["DebugProfile.entitlements", "Release.entitlements"] {
            try updatePlist(nativeRoot + "Runner/\(file)", values: ["keychain-access-groups": ["$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)"]])
        }
    }
    print("Configured \(platform) dev/prod schemes and Firebase selection.")
}
