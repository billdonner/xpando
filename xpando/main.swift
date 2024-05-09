//
//  main.swift
//  xpando
//
//  Created by bill donner on 1/3/24.
//

import Foundation
import ArgumentParser
import q20kshare
 
let dateFormatter = DateFormatter()
let csvcols = "Notes,Op,Question,Correct,Hint,Topic,Ans-1,Ans-2,Ans-3,Ans-4,Path,Date,Model"

var outcsv:String = ""
var incsv:String = ""
var replaced = 0
var deleted = 0

var processed = 0
var included = 0

var allQuestions:[(Challenge,Path)] = []
var allNotes:[String:String] = [:]


struct Xpando: ParsableCommand {
  
  static let configuration = CommandConfiguration(
    abstract: "XPANDO Builds The Files Needed By QANDA Mobile App and CSV\n\n***Pay heed to the tdPath argument which is an optional json input file made by SubtopicMaker that controls mapping of topics into subtopics. \n***Pay heed to the input-csv-file argument which is a json input which controls deletions and repairs of particular challenges.",
    version: "0.3.16",
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
  @Option(name: .shortAndLong, help: "full path to the topics data file.TURN THIS OFF IF YOU WANT TO PROCESS SUBTOPICS.")
  var tdPath: String = ""
  @Option(name: .shortAndLong, help: "full path to the ios output file.")
  var mobileFile: String = ""
  @Option(name: .shortAndLong, help: "full path to the csv output file.")
  var outputCSVFile: String = ""
  @Option(name: .shortAndLong, help: "Input CSV file path")
  var inputCSVFile: String = ""

  mutating func run() throws {
    var subTopicTree:[String:String]=[:]
    var topicData:TopicGroup =  TopicGroup(description: "missing", version: "0.0.0", author: "freeport", date: "never", topics: [])
    let decoder = JSONDecoder()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS" // "SS" is for hundredths of a second
    
    // move some command arg strings into globals
    
    outcsv = outputCSVFile
    incsv = inputCSVFile
    print("Xpando version \(Self.configuration.version)")
    let allfilters = filter == "" ? []:filter.components(separatedBy: ",")
    print(">Processing: ",directoryPaths.joined(separator:","))
    print(">Filters: ",allfilters.joined(separator: ","))
    if tdPath != "" {
       topicData =   fetchTopicData(tdPath)
      print(">Topics in topicData: \(topicData.topics.count)")
      subTopicTree = buildSubtopics(topicData)
    }

    // process incoming csv if we have one
    
    if inputCSVFile != "" {    process_incoming_csv() }
    for dp in directoryPaths {
      
      //walk thru all the files in the directorypaths
      expand(dirPath: dp) { fullpath ,filename in
        if !fullpath.hasPrefix(".") {
          processed += 1
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
                  allQuestions.append((capitalized(challenge),fullpath))   // fix topic capitalization issues
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
    }
    print(">Filter string: \(filter) selected \(included) of \(processed)")

    if dedupe {
      let  dupes = deduplicate()
      print(">Exact Duplicates detected: \(dupes)")
    }

    // produce CSV file for numbers, excel
    if outputCSVFile != "" {
      try csv_essence(challenges:allQuestions, outputCSVFile: outputCSVFile, subtopics: subTopicTree)
    }
    
    // now blend for ios
    if mobileFile != "" {
      let playdata = try iosBlender(allQuestions, tdPath: tdPath, subTopicTree: subTopicTree,topicData:topicData )
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
