//
//  csvhandling.swift
//  xpando
//
//  Created by bill donner on 1/21/24.
//

import Foundation
import q20kshare


func headerCSV() -> String {
  return csvcols + "\n"
}

func onelineCSV(from c:Challenge,atPath:String,subtopics:[String:String]) -> String {
  let topic = subtopics[c.topic] ?? c.topic
  var hint = c.hint.fixup
  if !hint.hasSuffix(".") { // if no period then add one 
    hint = hint + "."
  }
  let notes = allNotes[atPath] ?? ""
  var line = notes + "," + "," + c.question.fixup
  + "," + c.correct.fixup + ","  + hint + ","
  + normalize(topic).fixup + ","
  var done = 0
  for a in c.answers.dropLast(max(0,c.answers.count-4)) {
    line += a.fixup + ","
    done += 1
  }
  for _ in done..<4 {
    line += ","
  }
  let pdate = dateFormatter.string(from:c.date)
  line +=  atPath + "," + pdate + ","  + c.aisource.fixup
  return line + "\n" // need to separate
}
func parseCSVLine(_ line: String) -> [String] {
    var fields: [String] = []
    var currentField = ""
    var insideQuotes = false
    
    var previousChar: Character = "\0" // Use NULL character as a default previous character
    for char in line {
        switch char {
        case "\"":
            // Check for escaped quote only if previously inside quotes
            if insideQuotes {
                if previousChar == "\"" {
                    if !currentField.isEmpty {
                        currentField.removeLast() // Safely remove the last added quote
                    }
                    currentField.append(char) // Treat it as a quote within the value
                } // No 'else' needed here; we only toggle 'insideQuotes' when it's NOT escaped
            }
            insideQuotes.toggle()
        case ",":
            if insideQuotes {
                // Comma is part of the value
                currentField.append(char)
            } else {
                // Comma is a field delimiter, add field to result and reset currentField
                fields.append(currentField)
                currentField = ""
            }
        default:
            // Regular character, just add to current field
            currentField.append(char)
        }
        previousChar = char // Update previousChar at the end of the loop
    }
    
    // Add the last field after the loop ends
    fields.append(currentField)
    
    return fields.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
}
func csv_essence( challenges:[(Challenge,Path)],outputCSVFile: String,subtopics:[String:String]) throws {
  
  if challenges.count == 0 { print("No challenges in input"); return}
  
  if (FileManager.default.createFile(atPath:outputCSVFile, contents: nil, attributes: nil)) {
  } else {
    print("\(outputCSVFile) not created."); return
  }
  let outputHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: outputCSVFile))
  outputHandle.write(headerCSV().data(using:.utf8)!)
  var linecount = 0
  for challenge in challenges.sorted(by:{    if $0.0.date < $1.0.date { return true }
    else if $0.0.date > $1.0.date { return false }
    else { // equal id
      return $0.0.topic < $1.0.topic
    }}
  ) {
    let x = onelineCSV(from:challenge.0,atPath:challenge.1,subtopics:subtopics)
    outputHandle.write(x.data(using: .utf8)!)
    linecount += 1
  }
  try outputHandle.close()
  print(">Wrote \(linecount) lines to \(outputCSVFile)")
}
func process_incoming_csv() {
  print(">Decomposing \(incsv)")
  let colnames =  csvcols.components(separatedBy: ",")
  guard
    let idxdf = colnames.firstIndex(where: {$0=="Op"}),
    let  notesdf = colnames.firstIndex(where: {$0=="Notes"}),
    let  pathdf = colnames.firstIndex(where: {$0=="Path"})
  else
  {
    fatalError("internal column screwup")
  }
  var rownum = 0
  var processed = 0
  let fileURL = URL(fileURLWithPath: outcsv)
  do {
    // Read File Content
    let fileContentData = try String(contentsOf: fileURL)
    let fileContent = fileContentData.components(separatedBy: "\n")
    
    // Remove CSV header
    let rows = Array(fileContent.dropFirst())
    
    for row in rows {
      rownum += 1
      // Separate elements in the row
      
      let columns = parseCSVLine(row)
      // Check for valdity
      if columns.count != colnames.count {
        if columns.count != 1 { print (">Warning: Row \(rownum) Wrong column count \(columns.count) vs \(colnames.count), probably missing column") }
        continue
      }
      
      // Build a dictionary of all notes encountered
      let def = columns[notesdf].trimmingCharacters(in: .whitespacesAndNewlines)
      let path = columns[pathdf].trimmingCharacters(in: .whitespacesAndNewlines)
      if !def.isEmpty,!path.isEmpty  {
        allNotes[path] = def
      }
      
      // Process any opcode the user may have entered
      let df = columns[idxdf].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      let op:String  = df.first?.uppercased() ?? ""
      switch op {
      case "R" :
        trytoreplace(columns) 
      case "D"   :
        trytodelete(columns)
        
      default: break
      }
      processed += 1
    }
  } catch {
    print(">File reading error: \(error.localizedDescription)")
  }
  print(">Processed: \(processed), Replaced: \(replaced) Moved: \(deleted) Challenges to Purgatory")
  //print(allNotes)
}

func trytodelete(_ columns:[String]){
  let colnames =  csvcols.components(separatedBy: ",")
  guard
    let idxid = colnames.firstIndex(where: {$0=="Path"}),
    let questiondf = colnames.firstIndex(where: {$0=="Question"})
  else {
    print ("***columns screwup in tryto delete")
    return
  }
  
  let id = columns[idxid].trimmingCharacters(in: .whitespacesAndNewlines)
  let question = columns[questiondf].trimmingCharacters(in: .whitespacesAndNewlines)
  
  let fileManager = FileManager.default
  do {
    try fileManager.removeItem(atPath: id)
    print("Deleted \(question)")
    deleted+=1
  } catch let error as NSError {
    print("Couldn't delete: \(question)\n\(error.localizedDescription)")
  }
}

func trytoreplace(_ columns:[String]){
  let colnames =  csvcols.components(separatedBy: ",")
  guard
    let idxid = colnames.firstIndex(where: {$0=="Path"}),
    let idxq = colnames.firstIndex(where: {$0=="Question"}),
    let idxc = colnames.firstIndex(where: {$0=="Correct"}),
    let idxh = colnames.firstIndex(where: {$0=="Hint"}),
    let idx1 = colnames.firstIndex(where: {$0=="Ans-1"}),
    let idx2 = colnames.firstIndex(where: {$0=="Ans-2"}),
    let idx3 = colnames.firstIndex(where: {$0=="Ans-3"}),
    let idx4 = colnames.firstIndex(where: {$0=="Ans-4"}),
    let idxe = colnames.firstIndex(where: {$0=="Notes"}),
    let idxtopic = colnames.firstIndex(where: {$0=="Topic"})
  else {
    print ("***columns screwup in tryto replace")
    return
  }
  
  let path = columns[idxid].trimmingCharacters(in: .whitespacesAndNewlines)
  let question = columns[idxq].trimmingCharacters(in: .whitespacesAndNewlines)
  let correct = columns[idxc].trimmingCharacters(in: .whitespacesAndNewlines)
  let hint = columns[idxh].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans1 = columns[idx1].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans2 = columns[idx2].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans3 = columns[idx3].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans4 = columns[idx4].trimmingCharacters(in: .whitespacesAndNewlines)
  let notes = columns[idxe].trimmingCharacters(in: .whitespacesAndNewlines)
  
  let topic = columns[idxtopic].trimmingCharacters(in: .whitespacesAndNewlines)
  // let date = columns[idxd].trimmingCharacters(in: .whitespacesAndNewlines)
  
  // read original file using the ID field which is really
  
  let fileManager = FileManager.default
  do {
    guard let contents =  fileManager.contents(atPath: path),
          let challenge = try? JSONDecoder().decode(Challenge.self,from:contents)
    else {
      print("Cannot decode item at \(path)")
      return
    }
    
    let originalid = challenge.id
   // let originaltopic = challenge.topic
    let orginalaisource = challenge.aisource
    
    // make  new challenge and rewrite to filesystem
    
    let newchallenge = Challenge(question: question, topic: topic , hint: hint, answers: [ans1,ans2,ans3,ans4], correct: correct, explanation: challenge.explanation, id: originalid, date: Date(), aisource: orginalaisource,notes:notes)
    
    if let data = try? JSONEncoder().encode(newchallenge){
      print("replacing contents at path " + path)
      print("revised question is \(question)")
      writeDataToFile(data: data, filePath: path)
    }
    replaced += 1
  }
}
