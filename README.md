#  XPANDO - make ReadyForIOS1

version 0.2.7 runs purgatoried within
  - one new argument specifies input csvfile with lines to replace and delete items
  - flags are now "-m" for readyforios1, "-i" for inputcsvfile "-o" for outputfile

version 0.2.6 introduce sub-topics:
 - each topic now has a few subtopics, which are named just like topics
 - the AI deals with subtopics viq the pumpuser.txt script
 - Xpando joins together the subtopics into regular topics via readyforios1
 

version 0.2.5 normalize topic names:
- convert spaces and tabs to _ underscore _
- convert everything thats not alphanumeric to dashes
- capitalize the first letter of each word
- trim and squeeze out unnecessary spaces and tabs

## Takes Multiple Outputs from T9 and Bends Them Into IOS APP Format 

## Command Line


```
OVERVIEW: Bender Builds The Files Needed By QANDA Mobile App

USAGE: bender <json-files> ... [--output-file <output-file>] [--td-path <td-path>]

ARGUMENTS:
  <json-files>            The data files to be merged.

OPTIONS:
  -o, --output-file <output-file>
                          The name of the output file. (default:
                          merged_output.json)
  -t, --td-path <td-path> The name of the topics data file . (default:
                          TopicData.json)
  --version               Show the version.
  -h, --help              Show help information.
```
