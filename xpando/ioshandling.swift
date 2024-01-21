//
//  ioshandling.swift
//  xpando
//
//  Created by bill donner on 1/21/24.
//

import Foundation
import q20kshare

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
