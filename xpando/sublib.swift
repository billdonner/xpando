//
//  sublib.swift
//  xpando
//
//  Created by bill donner on 1/21/24.
//

import Foundation
import q20kshare

func writeDataToFile(data:Data, filePath: String) {
  do {
    // Write data to file
    try data.write(to: URL(fileURLWithPath: filePath))
  } catch {
    print("Error writing string to file: \(error.localizedDescription)")
  }
}

func normalize(_ str: String) -> String {
  
  // Trim and squeeze out unnecessary spaces and tabs
  var result = str.trimmingCharacters(in: .whitespacesAndNewlines)
  let components = result.components(separatedBy: .whitespacesAndNewlines)
  result = components.filter { !$0.isEmpty }.joined(separator: " ")
  
  // Capitalize the first letter of each word
  result = result.capitalized
  
  // Convert spaces and understores to underscores
  result = result.replacingOccurrences(of: " ", with: "_")
  
  // Convert everything thats not alphanumeric (or underscore or quote) to dashes
  result = result.replacingOccurrences(of: "[^a-zA-Z0-9_']+", with: "-", options: .regularExpression)
  
  return result
}

func testNormalize() {
  
  
  func test(_ s:String) {
    let p = normalize(s)
    print(p)
    let url = URL.documentsDirectory.appending(path:p)
    if FileManager.default.createFile(atPath:url.path, contents: nil, attributes: nil){
    } else {
      print("\(p) not created."); return
    }
    do{
   
      try FileManager.default.removeItem(at:url)
    }
    catch { print("\(p) not removed")}
    
  }
  test("i like coffee")
  test("I Don't Like Tea")
  test ("PLANES, TRAINS, AND Automobiles")
}

extension Challenge:Comparable {
  public static func < (lhs:  Challenge, rhs:  Challenge) -> Bool {
    lhs.question < rhs.question
  }
}
extension String {
  var fixup : String {
    return self.replacingOccurrences(of: ",", with: ";")
  }
}
func expand2(dirPaths: [String], filterCallback: (String,String ) -> Bool) {
  let fileManager = FileManager.default
  
  for dirPath in dirPaths {
    guard let dirContents = try? fileManager.contentsOfDirectory(atPath: dirPath) else {
      continue
    }
    let fullPaths = dirContents.compactMap  {!$0.hasPrefix(".") ? "\($0)" : nil}
    let _ = fullPaths.filter { filterCallback(dirPath.appending("/\($0)") , $0) }
    
  }
}

func expand(dirPath: String, filterCallback: (String, String) -> Bool) {
    let fileManager = FileManager.default

    // Attempt to get the directory contents
    guard let dirContents = try? fileManager.contentsOfDirectory(atPath: dirPath) else {
        // If we can't access this directory, end recursion here
        return
    }

    for entry in dirContents {
        // Skip hidden files and directories (those starting with a dot)
        guard !entry.hasPrefix(".") else {
            continue
        }

        // Construct the full path for the current entry
        let fullPath = dirPath.appending("/\(entry)")

        // Determine if the fullPath is a directory
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
            // If the entry is a directory, recurively expand it
            if isDirectory.boolValue {
                expand(dirPath: fullPath, filterCallback: filterCallback)
            } else {
                // Otherwise, apply the filterCallback
                _ = filterCallback(fullPath, entry)
            }
        }
    }
}



func contained(_ string: String, within: String) -> Bool {
  return within.range(of: string, options: .caseInsensitive) != nil
}

func capitalized(_ x:Challenge) -> Challenge   {
  Challenge(question: x.question, topic: normalize(x.topic), hint: x.hint, answers: x.answers, correct: x.correct,
            explanation: x.explanation, id: x.id, date: x.date,aisource: x.aisource)
  
}
