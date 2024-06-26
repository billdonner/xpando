#  XPANDO - make ReadyForIOS1

version 0.3.22 name backup file xxx-save.csv, dont write output files

version 0.3.21 ensure explanaton is rewritten

version 0.3.20 add explanaton field to csv input/output

version 0.3.19 setting notes field in csv pushes change into repaired challenge file, be sure to set repairflag in Op field 

version 0.3.18 make 2 output copies; make 2 input copies

version 0.3.17 fixes bugs - no data in output csv file

version 0.3.16 has better error messages

version 0.3.15 make <outputfile>.csv unique

version 0.3.14 dont complain if tdinfo missing with -t

version 0.3.13 allow editing of topic and always use original topic 

version 0.3.12 improve error reporting

version 0.3.11 fix crash when field starts with a quote

version 0.3.10 don't molest topic names

version 0.3.9 fix preserve notes field in csv

version 0.3.8 preserve notes field in csv

version 0.3.7 capitalize topic name regardless of chatgpt 
              adds period to end of hint if not already present

version 0.3.6 fixes csv output and allows better topic names

version 0.3.5 adds missing bundleid

version 0.3.4 add notes field on left of spreadsheet for humans,remove explanation col

version 0.3.3 fix bug inserting multiple duplicate topics into readyforios

version 0.3.2 fix path bug

version 0.3.1 reorder csv fileds, include date, allow input csv to be missing

version 0.3.0 ensures output in both json and csv is sorted by date

version 0.2.9 fixes problem with hidden files appearing in the scan

version 0.2.8 improves and repairs normalization


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

## Takes Multiple Outputs from T9 and Converts Them Into CSV and IOS APP Format 
- an auxillay file Topic-Info.Json supplies details of subtopics
- subtopics from T9 are blended into full topics 

## Command Line

```
OVERVIEW: XPANDO Builds The Files Needed By QANDA Mobile App and CSV

***Pay heed to the tdPath argument which is an optional json input file made by
SubtopicMaker that controls mapping of topics into subtopics. 
***Pay heed to the input-csv-file argument which is a json input which controls
deletions and repairs of particular challenges.

USAGE: xpando <directory-paths> ... [--filter <filter>] [--quiet <quiet>] [--dedupe <dedupe>] [--td-path <td-path>] [--mobile-file <mobile-file>] [--output-csv-file <output-csv-file>] [--input-csv-file <input-csv-file>]

ARGUMENTS:
  <directory-paths>       List of directory paths.

OPTIONS:
  --filter <filter>       filter string
  --quiet <quiet>         quiet (default: false)
  --dedupe <dedupe>       dedupe (default: true)
  -t, --td-path <td-path> full path to the topics data file.TURN THIS OFF IF
                          YOU WANT TO PROCESS SUBTOPICS.
  -m, --mobile-file <mobile-file>
                          full path to the ios output file.
  -o, --output-csv-file <output-csv-file>
                          full path to the csv output file.
  -i, --input-csv-file <input-csv-file>
                          Input CSV file path
  --version               Show the version.
  -h, --help              Show help information.
```
