//
//  main.swift
//  xpando
//
//  Created by bill donner on 1/3/24.
//

import Foundation
import ArgumentParser
import q20kshare
struct GroupTopicCounts {
  var topic:String
  var count:Int
}

var outcsv:String = ""
var incsv:String = ""
var replaced = 0
var deleted = 0

var processed = 0
var included = 0
var allQuestions:[Challenge] = []

func writeDataToFile(data:Data, filePath: String) {
  do {
    // Write data to file
    try data.write(to: URL(fileURLWithPath: filePath))
  } catch {
    print("Error writing string to file: \(error.localizedDescription)")
  }
}

func trytodelete(_ columns:[String]){
  let colnames = q20kshare_csvcols.components(separatedBy: ",")
  guard
    let idxid = colnames.firstIndex(where: {$0=="ID"}),
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
//"DELETEFLAG,Question,Correct,Topic,Model,Hint,Ans-1,Ans-2,Ans-3,Ans-4,Explanation,ID"

func trytoreplace(_ columns:[String]){
  let colnames = q20kshare_csvcols.components(separatedBy: ",")
  guard
    let idxid = colnames.firstIndex(where: {$0=="ID"}),
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
  
  let id = columns[idxid].trimmingCharacters(in: .whitespacesAndNewlines)
  let question = columns[idxq].trimmingCharacters(in: .whitespacesAndNewlines)
  let correct = columns[idxc].trimmingCharacters(in: .whitespacesAndNewlines)
  //let model = columns[idxm].trimmingCharacters(in: .whitespacesAndNewlines)
  let hint = columns[idxh].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans1 = columns[idx1].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans2 = columns[idx2].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans3 = columns[idx3].trimmingCharacters(in: .whitespacesAndNewlines)
  let ans4 = columns[idx4].trimmingCharacters(in: .whitespacesAndNewlines)
  let explanation = columns[idxe].trimmingCharacters(in: .whitespacesAndNewlines)
  
  // read original file using the ID field which is really
  
  let fileManager = FileManager.default
  do {
    guard let contents =  fileManager.contents(atPath: id),
          let challenge = try? JSONDecoder().decode(Challenge.self,from:contents)
    else {
      print("Cannot decode item at \(id)")
      return
    }
    
    let originalid = challenge.id
    let originaltopic = challenge.topic
    let orginalaisource = challenge.aisource
    
    // make  new challenge and rewrite to filesystem
    
    let newchallenge = Challenge(question: question, topic: originaltopic, hint: hint, answers: [ans1,ans2,ans3,ans4], correct: correct, explanation: explanation, id: originalid, date: Date(), aisource: orginalaisource)
    
    if let data = try? JSONEncoder().encode(newchallenge){
      print("replacing contents at path " + id)
      print("revised question is \(question)")
      writeDataToFile(data: data, filePath: id)
    }
    replaced += 1
  }
}

func process_incoming_csv() {
  print(">Decomposing \(incsv)")
  let colnames = q20kshare_csvcols.components(separatedBy: ",")
  print(colnames)
  guard
    //let idxid = colnames.firstIndex(where: {$0=="ID"}),
    let idxdf = colnames.firstIndex(where: {$0=="DELETEFLAG"})
      //let questiondf = colnames.firstIndex(where: {$0=="Question"})
  else
  {
    fatalError("internal column screwup")
  }
  var rownum = 0
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
        print (">Warning: Row \(rownum) Wrong column count \(columns.count) vs \(colnames.count), probably missing extra DELETEFLAG column")
        continue
      }
      if columns.count < colnames.count {
        continue
      }
      
      let df = columns[idxdf].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      
      if df != "" {
        print (df)
      }
      switch df {
        
      case "replaceflag" :
        trytoreplace(columns)
        
      case "deleteflag"   :
        trytodelete(columns)
        
      default: break
      }
    }
  } catch {
    print(">File reading error: \(error.localizedDescription)")
  }
  print(">Processed: \(rownum), Replaced: \(replaced) Moved: \(deleted) Challenges to Purgatory")
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
func headerCSV() -> String {
  return q20kshare_csvcols + "\n"
}

func onelineCSV(from c:Challenge,atPath:String,subtopics:[String:String]) -> String {
  let topic = subtopics[c.topic] ?? c.topic
  var line =  "," + c.question.fixup + "," + c.correct.fixup + "," + normalize(topic).fixup + "," + c.aisource.fixup +  "," + c.hint.fixup + ","
  var done = 0
  for a in c.answers.dropLast(max(0,c.answers.count-4)) {
    line += a.fixup + ","
    done += 1
  }
  for _ in done..<4 {
    line += ","
  }
  line +=  (c.explanation?.fixup ?? "") +  "," + atPath
  return line + "\n" // need to separate
}

func csv_essence( challenges:[Challenge],outputCSVFile: String,fullpaths:[String],subtopics:[String:String]) throws {
  
  if challenges == [] { print("No challenges in input"); return}
  
  if (FileManager.default.createFile(atPath:outputCSVFile, contents: nil, attributes: nil)) {
  } else {
    print("\(outputCSVFile) not created."); return
  }
  let outputHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: outputCSVFile))
  outputHandle.write(headerCSV().data(using:.utf8)!)
  var linecount = 0
  for challenge in challenges.sorted(by:{    if $0.date < $1.date { return true }
    else if $0.date > $1.date { return false }
    else { // equal id
      return $0.topic < $1.topic
    }}
    ) {
    let x = onelineCSV(from:challenge,atPath:fullpaths[linecount],subtopics:subtopics)
    outputHandle.write(x.data(using: .utf8)!)
    linecount += 1
  }
  try outputHandle.close()
  print(">Wrote \(linecount) lines to \(outputCSVFile)")
}

func fetchTopicData(_ tdurl:String ) throws -> TopicGroup {
  // Load substitutions JSON file,throw out all of the metadata for now
  let xdata = try Data(contentsOf: URL(fileURLWithPath: tdurl))
  let decoded = try JSONDecoder().decode(TopicGroup.self, from:xdata)
  // normalize the topic names
  var newtops:[Topic]=[]
  for topic in decoded.topics {
    newtops.append(Topic(name:normalize(topic.name),subject:normalize(topic.subject),pic:topic.pic,notes:topic.notes,subtopics: topic.subtopics))
  }
  let newTopicData:TopicGroup = TopicGroup(description: decoded.description, version: decoded.version, author: decoded.author, date: decoded.date, topics: newtops)
  return newTopicData
}

func buildSubtopics (_ topicData: TopicGroup) -> [String:String] {
  var subTopicTree : [String:String ] = [:]
  for topic in topicData.topics {// subtopics are optional
    // print(topic,topic.subtopics)
    for subtopic in topic.subtopics  {
      if  let zzz = subTopicTree[normalize(subtopic)] {
        print("Warning subtopic \(subtopic) is already in topic \(zzz) but you are trying to also add it to topic \(topic)")
      } else {
        // not in tree so add it
        subTopicTree[normalize(subtopic)] = normalize(topic.name)
      }
    }
  }
  // print the subtopic tree
  if subTopicTree != [:] {
    print("===SubTopics===")
    for z in subTopicTree.enumerated() {
      print(z.offset,z.element)
    }
  }
  return subTopicTree
}

func blend(_ mergedData:[Challenge],tdPath:String,subTopicTree:[String:String],topicData:TopicGroup) throws -> PlayData {
  
  var dedupedData: [Challenge] = []
  // dedupe phase I = sort by ID then by reverse time
  let x = mergedData.sorted(by:) {
    if $0.id < $1.id { return true }
    else if $0.id > $1.id { return false }
    else { // equal id
      return $0.date > $1.date
    }
  }
  var lastid = ""
  // dont copy if same as last id
  for challenge in x {
    if challenge.id != lastid {
      //modify the challenge so it uses subtopics if e have one
      if let zz = subTopicTree[challenge.topic] {
        let modchallenge = Challenge(question: challenge.question, topic: zz, hint: challenge.hint, answers: challenge.answers, correct: challenge.correct, explanation: challenge.explanation, id: challenge.id, date: challenge.date, aisource: challenge.aisource)
        dedupedData.append(modchallenge)
      } else {
        dedupedData.append(challenge)
      }
      lastid = challenge.id
    }
  }
  
  // now sort by topic and time
  dedupedData.sort(by:) {
    if $0.date < $1.date { return true }
    else if $0.date > $1.date { return false }
    else { // equal id
      return $0.topic < $1.topic
    }
  }
  if dedupedData.count != mergedData.count {
    print("\(mergedData.count - dedupedData.count) duplicates removed")
  }
  
  // now produce a topic manifest
  
  var lasttopic = ""
  var topicitems = 0
  var groupTopicCounts:[GroupTopicCounts] = []
  for d in dedupedData {
    if d.topic != lasttopic {
      if topicitems != 0 {
        groupTopicCounts.append(GroupTopicCounts(topic: normalize(lasttopic),count: topicitems))
      }
      lasttopic = d.topic
      topicitems = 1
    } else {
      topicitems += 1
    }
  }
  if topicitems != 0 {
    groupTopicCounts.append(GroupTopicCounts(topic: normalize(lasttopic),count: topicitems))
  }
  print("+======TOPICS======+")
  for e in groupTopicCounts {
    print (" \(e.topic)   \(e.count)  ")
  }
  print("+==================+")
  
  let topics =  groupTopicCounts.map {
    var pic = "pencil"
    var notes = "Notes for \(pic)"
    var subtopics :[String] = []
    var subj = $0.topic
    
    for td in topicData.topics {
      if $0.topic == td.name {
        subj = td.subject; pic = td.pic ; notes = td.notes; subtopics = td.subtopics; break
      }
    }
    return Topic(name: $0.topic, subject: subj, pic:pic,   notes: notes,subtopics: subtopics)
  }
  
  let rewrittenTd = TopicGroup(description:topicData.description,version:topicData.version,
                               author:topicData.author, date: "\(Date())",
                               topics:topics)
  
  var gamedatum: [GameData] = []
  for t in topics {
    var challenges:[Challenge] = []
    // crude
    for item in dedupedData {
      if item.topic == t.name  {
        challenges.append(item)//.makeChallenge())
      }
    }
    
    challenges.sort(by:) {
      if $0.topic < $1.topic { return true }
      else if $0.topic > $1.topic { return false }
      else { // equal id
        return $0.date < $1.date
      }
    }
    let gda = GameData(topic: t.name, challenges: challenges)
    gamedatum.append(gda)
  }
  
  return PlayData(topicData:rewrittenTd,
                  gameDatum: gamedatum,
                  playDataId: UUID().uuidString,
                  blendDate: Date() )
}
func expand(dirPaths: [String], filterCallback: (String,String ) -> Bool) {
  let fileManager = FileManager.default
  
  for dirPath in dirPaths {
    guard let dirContents = try? fileManager.contentsOfDirectory(atPath: dirPath) else {
      continue
    }
    let fullPaths = dirContents.compactMap  {!$0.hasPrefix(".") ? "\($0)" : nil}
    let _ = fullPaths.filter { filterCallback(dirPath.appending("/\($0)") , $0) }
    
  }
}
func contained(_ string: String, within: String) -> Bool {
  return within.range(of: string, options: .caseInsensitive) != nil
}

func capitalized(_ x:Challenge) -> Challenge   {
  Challenge(question: x.question, topic: normalize(x.topic), hint: x.hint, answers: x.answers, correct: x.correct,
            explanation: x.explanation, id: x.id, date: x.date,aisource: x.aisource)
  
}

func deduplicate() ->Int {
  var dupes = 0
  allQuestions.sort()
  var last : Challenge? = nil
  for q in allQuestions  {
    if let last = last  {
      if last == q {
        print (last.question,"with id:",last.id," has duplicate with id:",q.id)
        dupes += 1
      }
    }
    last = q
  }
  return dupes
}
struct Xpando: ParsableCommand {
  
  static let configuration = CommandConfiguration(
    abstract: "XPANDO Builds The Files Needed By QANDA Mobile App and CSV",
    version: "0.3.0",
    subcommands: [],
    defaultSubcommand: nil,
    helpNames: [.long, .short]
  )
  
  @Argument(help: "List of directory paths.")
  var directoryPaths: [String]
  @Option(help:"filter string")
  var filter = ""
  @Option(help:"quiet")
  var quiet = false
  @Option(help:"dedupe")
  var dedupe = true
  @Option(name: .shortAndLong, help: "full path to the topics data file.")
  var tdPath: String = ""
  @Option(name: .shortAndLong, help: "full path to the ios output file.")
  var mobileFile: String = ""
  @Option(name: .shortAndLong, help: "full path to the csv output file.")
  var outputCSVFile: String = ""
  @Option(name: .shortAndLong, help: "Input CSV file path")
  var inputCSVFile: String
  
  
  
  mutating func run() throws {
//    while true {
//      testNormalize()
//      sleep(3)
//    }
    let decoder = JSONDecoder()
    outcsv = outputCSVFile
    incsv = inputCSVFile
    print("Xpando version \(Self.configuration.version)")
    let allfilters = filter == "" ? []:filter.components(separatedBy: ",")
    print(">Processing: ",directoryPaths.joined(separator:","))
    print(">Filters: ",allfilters.joined(separator: ","))
    var fullPaths:[String] = []
    let topicData = try fetchTopicData(tdPath)
    // now build a dictionary marrying subtopics to their main topic
    let subTopicTree = buildSubtopics(topicData)
    // process incoming csv if we have one
    
    process_incoming_csv()
    
    
    //walk thru all the files in the directorypaths
    expand(dirPaths: directoryPaths) { fullpath ,filename in
      if !fullpath.hasPrefix(".") {
        processed += 1
        fullPaths.append(fullpath)
        // Your filter condition goes here
        // apply the filename filter
        var include = false
        if allfilters.count == 0 {
          include = true
        } else {
          for thefilter in allfilters {
            if contained(thefilter,within: filename) {
              include = true ; break
            }
          }
        }
        if include  {
          included += 1
          if dedupe {
            // open the file to get to the actual challenge
            if let data = try? Data(contentsOf: URL(fileURLWithPath: fullpath)) {
              if let challenge = try? decoder.decode(Challenge.self,from:data) {
                if !quiet {
                  print (challenge.question, ",",challenge.id)
                }
                // fix topic capitalization issues
                let t = capitalized(challenge)
                allQuestions.append(t)
              }
            }
          } else {
            // not deduping
            if !quiet {
              print (">selected: " + fullpath)
            }
          }
        }
        return include
      }
      return false
    }
    print(">Filter string: \(filter) selected \(included) of \(processed)")
    
    
    if dedupe {
      let  dupes = deduplicate()
      print(">Exact Duplicates detected: \(dupes)")
    }
    
    
    // produce CSV file for numbers, excel
    if outputCSVFile != "" {
      try csv_essence(challenges:allQuestions, outputCSVFile: outputCSVFile, fullpaths:fullPaths, subtopics: subTopicTree)
    }
    // now blend for ios
    if mobileFile != "" {
      let playdata = try blend(allQuestions, tdPath: tdPath, subTopicTree: subTopicTree,topicData:topicData )
      // write the deduped data
      let encoder = JSONEncoder()
      encoder.outputFormatting = .prettyPrinted
      do {
        let outputData = try encoder.encode(playdata)
        let outurl = URL(fileURLWithPath: mobileFile)
        try? outputData.write(to: outurl)
        print("Data files merged successfully - \(allQuestions.count) saved to \(mobileFile)")
      }
      catch {
        print("Encoding error: \(error)")
      }
    }
  }
}

Xpando.main()
