#  XPANDO - make ReadyForIOS1

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
