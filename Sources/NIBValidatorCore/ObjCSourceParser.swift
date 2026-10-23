//
//  ObjCSourceParser.swift
//  NIBStarter
//
//  Created by Adam Stern on 23/10/2026.
//

import Foundation

public final class ObjCSourceParser {
    
    public static func parse(source: String, fileURL: URL) -> [ClassCodeModel] {
        var results: [ClassCodeModel] = []
        
        // Locate interface and implementation blocks:
        // @interface ClassName ... @end or @implementation ClassName ... @end
        let blockRegex = try! NSRegularExpression(
            pattern: #"@(interface|implementation)\s+([a-zA-Z0-9_]+)(?:[^{}\n]*)(.*?)(?=@end|\z)"#,
            options: [.dotMatchesLineSeparators]
        )
        
        let nsSource = source as NSString
        let matches = blockRegex.matches(in: source, range: NSRange(location: 0, length: nsSource.length))
        
        for match in matches {
            guard match.numberOfRanges >= 4 else { continue }
            let className = nsSource.substring(with: match.range(at: 2))
            let body = nsSource.substring(with: match.range(at: 3))
            
            let outlets = extractOutlets(from: body)
            let actions = extractActions(from: body)
            
            if !outlets.isEmpty || !actions.isEmpty {
                results.append(ClassCodeModel(
                    className: className,
                    outlets: outlets,
                    actions: actions,
                    sourceFiles: [fileURL]
                ))
            }
        }
        
        return results
    }
    
    private static func extractOutlets(from body: String) -> Set<String> {
        var outlets: Set<String> = []
        
        // Matches: @property (...) IBOutlet Type *name;
        // Matches: IBOutlet Type *name;
        let outletRegex = try! NSRegularExpression(
            pattern: #"IBOutlet\s+[a-zA-Z0-9_*<>\s]+?\b([a-zA-Z0-9_]+)\s*;"#,
            options: []
        )
        
        let nsBody = body as NSString
        let matches = outletRegex.matches(in: body, range: NSRange(location: 0, length: nsBody.length))
        for match in matches where match.numberOfRanges >= 2 {
            outlets.insert(nsBody.substring(with: match.range(at: 1)))
        }
        
        return outlets
    }
    
    private static func extractActions(from body: String) -> Set<String> {
        var actions: Set<String> = []
        
        // Matches: - (IBAction)buttonTapped:(id)sender; or - (IBAction)buttonTapped;
        let actionRegex = try! NSRegularExpression(
            pattern: #"-\s*\(\s*IBAction\s*\)\s*([a-zA-Z0-9_]+)(\s*:\s*\([^)]*\)\s*[a-zA-Z0-9_]+)?"#,
            options: []
        )
        
        let nsBody = body as NSString
        let matches = actionRegex.matches(in: body, range: NSRange(location: 0, length: nsBody.length))
        for match in matches where match.numberOfRanges >= 2 {
            let baseName = nsBody.substring(with: match.range(at: 1))
            let hasParam = match.range(at: 2).location != NSNotFound
            let selector = hasParam ? "\(baseName):" : baseName
            actions.insert(selector)
            actions.insert(baseName)
        }
        
        return actions
    }
}
