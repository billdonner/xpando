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
    var newtops:[Topic]=[]
    for topic in decoded.topics {
      newtops.append(Topic(name:normalize(topic.name),subject:normalize(topic.subject),pic:topic.pic,notes:topic.notes,subtopics: topic.subtopics))
    }
    let newTopicData:TopicGroup = TopicGroup(description: decoded.description, version: decoded.version, author: decoded.author, date: decoded.date, topics: newtops)
    return newTopicData
  }
  catch {
    print("Cant read \(tdurl), substituting")
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
