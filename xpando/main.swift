//
//  main.swift
//  xpando
//
//  Created by bill donner on 1/3/24.
//

import Foundation
import ArgumentParser
import q20kshare

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
  return "DELETEFLAG,Question,Correct,Topic,Hint,Ans-1,Ans-2,Ans-3,Ans-4,Explanation,ID\n"
}

func onelineCSV(from c:Challenge,atPath:String) -> String {
  var line =  "," + c.question.fixup + "," + c.correct.fixup + "," + c.topic.fixup + "," + c.hint.fixup + ","
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

func flatten_essence( challenges:[Challenge],outputCSVFile: String,fullpaths:[String]) throws {

  if challenges == [] { print("No challenges in input"); return}

  if (FileManager.default.createFile(atPath:outputCSVFile, contents: nil, attributes: nil)) { 
  } else {
    print("\(outputCSVFile) not created."); return
  }
  let outputHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: outputCSVFile))
  outputHandle.write(headerCSV().data(using:.utf8)!)
  var linecount = 0
  for challenge in challenges {
    let x = onelineCSV(from:challenge,atPath:fullpaths[linecount])
    outputHandle.write(x.data(using: .utf8)!)
    linecount += 1
  }
  try outputHandle.close()
  print(">Wrote \(linecount) lines to \(outputCSVFile)")
}

func blend(_ mergedData:[Challenge],tdPath:String) throws -> PlayData {
  
  func fetchTopicData(_ tdurl:String ) throws -> TopicData {
    // Load substitutions JSON file,throw out all of the metadata for now
    let xdata = try Data(contentsOf: URL(fileURLWithPath: tdurl))
    let decoded = try JSONDecoder().decode(TopicData.self, from:xdata)
    return decoded
  }

  
  let topicData = try fetchTopicData(tdPath)
  let tdblocks = topicData.topics
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
  for d in x {
    if d.id != lastid {
      dedupedData.append(d)
      lastid = d.id
    }
  }
  // now sort by topic and time
  dedupedData.sort(by:) {
    if $0.topic < $1.topic { return true }
    else if $0.topic > $1.topic { return false }
    else { // equal id
      return $0.date < $1.date
    }
  }
  if dedupedData.count != mergedData.count {
    print("\(mergedData.count - dedupedData.count) duplicates removed")
  }
  // now produce a topic manifest
  struct Entry {
    var topic:String
    var count:Int
  }
  var lasttopic = ""
  var topicitems = 0
  var entries:[Entry] = []
  for d in dedupedData {
    if d.topic != lasttopic {
      if topicitems != 0 {
        entries.append(Entry(topic: lasttopic,count: topicitems))
      }
      lasttopic = d.topic
      topicitems = 1
    } else {
      topicitems += 1
    }
  }
  if topicitems != 0 {
    entries.append(Entry(topic: lasttopic,count: topicitems))
  }
  print("+======TOPICS======+")
  for e in entries {
    print (" \(e.topic)   \(e.count)  ")
  }
  print("+==================+")
  
  let topics =  entries.map {
    var pic = "pencil"
    var notes = "Notes for \(pic)"
    for td in tdblocks {
      if $0.topic == td.name { pic = td.pic ; notes = td.notes; break}
    }
    return Topic(name: $0.topic, subject: $0.topic, pic:pic,   notes: notes)
  }
 
  let rewrittenTd = TopicData(description:topicData.description,version:topicData.version,
                     author:topicData.author, date: "\(Date())",
                     purpose:topicData.purpose,topics:topics)
  
  var gamedatum: [GameData] = []
  for t in topics {
    var challenges:[Challenge] = []
    // crude
    for item in dedupedData {
      if item.topic == t.name  {
        challenges.append(item)//.makeChallenge())
      }
    }
    let gda = GameData(topic: t.name, challenges: challenges)
    gamedatum.append(gda)
  }

  let playdata = PlayData(topicData:rewrittenTd,
                          gameDatum: gamedatum,
                          playDataId: UUID().uuidString,
                          blendDate: Date() )
  
return playdata
}
func expand(dirPaths: [String], filterCallback: (String,String ) -> Bool) {
    let fileManager = FileManager.default
    
    for dirPath in dirPaths {
        guard let dirContents = try? fileManager.contentsOfDirectory(atPath: dirPath) else {
            continue
        }
        let fullPaths = dirContents.map { "\($0)"} //{ dirPath.appending("/\($0)") }
        let _ = fullPaths.filter { filterCallback(dirPath.appending("/\($0)") , $0) }

    }
}
func contained(_ string: String, within: String) -> Bool {
    return within.range(of: string, options: .caseInsensitive) != nil
}
 
struct Xpando: ParsableCommand {
  
  static let configuration = CommandConfiguration(
    abstract: "XPANDO Builds The Files Needed By QANDA Mobile App and More",
    version: "0.1.9",
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
  @Option(name: .shortAndLong, help: "The name of the topics data file .")
  var tdPath: String = "TopicData.json"
  @Option(name: .shortAndLong, help: "The name of the ios output file.")
  var iosFile: String = "readyforiosx.json"
  @Option(name: .shortAndLong, help: "The name of the csv output file.")
  var csvFile: String = "flattened.csv"
  
  
    var processed = 0
    var included = 0
    var allQuestions:[Challenge] = []
  
    mutating func run() throws {
      let decoder = JSONDecoder()
      let allfilters = filter == "" ? []:filter.components(separatedBy: ",")
      print(">Processing: ",directoryPaths.joined(separator:","))
      print(">Filters: ",allfilters.joined(separator: ","))
      var fullPaths:[String] = []
        expand(dirPaths: directoryPaths) { fullpath ,filename in
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
                   allQuestions.append(challenge)
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
      print(">Filter string: \(filter) selected \(included) of \(processed)")
      
      
      if dedupe {
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
        print(">Exact Duplicates detected: \(dupes)")
        
        
        // produce CSV file for numbers, excel
        if csvFile != "" {
          try flatten_essence(challenges:allQuestions, outputCSVFile: csvFile, fullpaths:fullPaths)
        }
        // now blend for ios
        if iosFile != "" {
          let playdata = try blend(allQuestions, tdPath: tdPath)
          // write the deduped data
          let encoder = JSONEncoder()
          // encoder.dateEncodingStrategy = .iso8601
          encoder.outputFormatting = .prettyPrinted
          do {
            let outputData = try encoder.encode(playdata)
            let outurl = URL(fileURLWithPath: iosFile)
            try? outputData.write(to: outurl)
            print("Data files merged successfully - \(allQuestions.count) saved to \(iosFile)")
          }
          catch {
            print("Encoding error: \(error)")
          }
        }
      }
    }
}

Xpando.main()
