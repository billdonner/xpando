//
//  sublib.swift
//  xpando
//
//  Created by bill donner on 1/21/24.
//

import Foundation
import q20kshare

typealias Path = String

struct GroupTopicCounts {
  var topic:String
  var count:Int
}


extension Challenge:Comparable {
  public static func < (lhs:  Challenge, rhs:  Challenge) -> Bool {
    lhs.question < rhs.question
  }
}

extension String {
  var fixup : String {
    // Check if encoding is needed
    if self.contains(",") || self.contains("\"") {
      // Replace all instances of double quotes with two double quotes
      let escapedQuotes = self.replacingOccurrences(of: "\"", with: "\"\"")
      // Enclose the entire string in double quotes
      return "\"\(escapedQuotes)\""
    } else {
      // No encoding needed
      return self
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

func challengesFor(topic:String,ch:[Challenge]) -> [Challenge] {
  ch.compactMap()  { $0.topic == topic ? $0:nil }
}
func writeDataToFile(data:Data, filePath: String) {
  do {
    // Write data to file
    try data.write(to: URL(fileURLWithPath: filePath))
  } catch {
    print("Error writing string to file: \(error.localizedDescription)")
  }
}

func normalize(_ str: String) -> String {
  return str//.capitalized
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




// not really eliminating dupes, just counting
func deduplicate() ->Int {
  var dupes = 0
  allQuestions.sort(by:) {
    let (c0,p0) = $0
    let (c1,p1) = $1
    if c0.id < c1.id {
      return true
    } else
      if c0.id > c1.id {
        return false
      }
    else {
      return p0 <= p1
    }
  }
  var last : Challenge? = nil
  for q in allQuestions  {
    if let last = last  {
      if last == q.0 {
        print (last.question,"with id:",last.id," has duplicate with id:",q.0.id)
        dupes += 1
      }
    }
    last = q.0
  }
  return dupes
}
