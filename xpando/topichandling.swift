//
//  topichandling.swift
//  xpando
//
//  Created by bill donner on 1/21/24.
//

import Foundation
import q20kshare

func fetchTopicData(_ tdurl:String )   -> TopicGroup {
  // Load substitutions JSON file,throw out all of the metadata for now
  do {
    let xdata = try Data(contentsOf: URL(fileURLWithPath: tdurl))
    let decoded = try JSONDecoder().decode(TopicGroup.self, from:xdata)
    // normalize the topic names
    var newtops:[Topic] =  decoded.topics.map{ topic in
      Topic(name:normalize(topic.name),subject:topic.subject,pic:topic.pic,notes:topic.notes,subtopics: topic.subtopics)
    }
    // sort the topicnames
    
    newtops.sort(by:){
      $0.name < $1.name
    }
    // check for dupes
    var lasttop = ""
    for top in newtops {
      if top.name == lasttop {
        print("warning: topic \(top.name) is a duplicate")
      }
      lasttop = top.name
    }
    print(">Fetched \(newtops.count) topics")
    return TopicGroup(description: decoded.description, version: decoded.version, author: decoded.author, date: decoded.date, topics: newtops) 
  }
  catch {
    print("Cant read \(tdurl),\n \(error)")
    return TopicGroup(description: "missing", version: "0.0.0", author: "freeport", date: "never", topics: [])
  }
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

