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
  var line =  "," + c.question.fixup + "," + c.correct.fixup + ","  + c.hint.fixup + ","
  + (c.explanation?.fixup ?? "")  +  "," +  normalize(topic).fixup + ","
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
    //let idxid = colnames.firstIndex(where: {$0=="ID"}),
    let idxdf = colnames.firstIndex(where: {$0=="Op"})
      //let questiondf = colnames.firstIndex(where: {$0=="Question"})
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
      let columns = row.components(separatedBy: ",")
      
      // Check for column 9 and column 10
      if columns.count > colnames.count {
        print (">Warning: Row \(rownum) Wrong column count \(columns.count) vs \(colnames.count), probably missing column")
        continue
      }
      if columns.count < colnames.count {
        continue
      }
      
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
}

func trytodelete(_ columns:[String]){
  let colnames =  csvcols.components(separatedBy: ",")
  guard
    let idxid = colnames.firstIndex(where: {$0=="Path"}),
    let questiondf = colnames.firstIndex(where: {$0=="Question"})
  else {
    print ("columns screwup in tryto delete")
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
    //let idxm = colnames.firstIndex(where: {$0=="Model"}),
    let idxh = colnames.firstIndex(where: {$0=="Hint"}),
    let idx1 = colnames.firstIndex(where: {$0=="Ans-1"}),
    let idx2 = colnames.firstIndex(where: {$0=="Ans-2"}),
    let idx3 = colnames.firstIndex(where: {$0=="Ans-3"}),
    let idx4 = colnames.firstIndex(where: {$0=="Ans-4"}),
    let idxe = colnames.firstIndex(where: {$0=="Explanation"})
  else {
    print ("columns screwup in tryto replace")
    return
  }
  
  let path = columns[idxid].trimmingCharacters(in: .whitespacesAndNewlines)
  let question = columns[idxq].trimmingCharacters(in: .whitespacesAndNewlines)
  let correct = columns[idxc].trimmingCharacters(in: .whitespacesAndNewlines)
  //let model = columns[idxm].trimmingCharacters(in: .whitespacesAndNewlines)
  let hint = columns[idxh].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans1 = columns[idx1].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans2 = columns[idx2].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans3 = columns[idx3].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans4 = columns[idx4].trimmingCharacters(in: .whitespacesAndNewlines)
  let explanation = columns[idxe].trimmingCharacters(in: .whitespacesAndNewlines)
  
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
    let originaltopic = challenge.topic
    let orginalaisource = challenge.aisource
    
    // make  new challenge and rewrite to filesystem
    
    let newchallenge = Challenge(question: question, topic: originaltopic, hint: hint, answers: [ans1,ans2,ans3,ans4], correct: correct, explanation: explanation, id: originalid, date: Date(), aisource: orginalaisource)
    
    if let data = try? JSONEncoder().encode(newchallenge){
      print("replacing contents at path " + path)
      print("revised question is \(question)")
      writeDataToFile(data: data, filePath: path)
    }
    replaced += 1
  }
}
