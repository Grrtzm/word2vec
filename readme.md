## Using Word2Vec for ‘Anomaly Detection’ in Windows Eventlogs
### _This is just a proof of concept, not a final product!_
---
I used two different implementations of Word2Vec; [the popular Gensim version](https://github.com/Grrtzm/word2vec/blob/main/windows_eventlog_anomaly_detection_with_gensim_word2vec.ipynb) and [one built in Tensorflow](https://github.com/Grrtzm/word2vec/blob/main/windows_eventlog_anomaly_detection_with_tensorflow_word2vec.ipynb).
The goal was to reproduce the same results in both versions, but i could not exactly reproduce the same results. Neither of them is an exact implementation of [the original Word2Vec algoritm](https://code.google.com/p/word2vec/).
I didn't dig very deep, but if you only look at the way the vocabularies are built, you can guess why Gensim is more accurate.
Gensim built a vocabulary where the weight for each word is the word count in the corpus. For Tensorflow the weight is a counter; the event that occurs most is #1, the event that occurs least has the highest number (while there are several events that only occur once, so what happens then?).

After every training you get different 'Top 10' results, it varies every time. This applies for both the Gensim as well as the Tensorflow version.
You can save the model. Using a saved model gives you consistent results.

The Gensim version (based on gensim 4.1.2) is a bit of a black box, but i trust it to look more like the original Word2Vec. It seems to produce more consistent results.
Take a look at the results at the bottom of both notebooks.

Both were inspired on tutorials. You can find the links in the headers of my Jupyter Notebooks.

-----
## Instructions for use
-----

You can't just copy event log files, they are locked by the operating system.

To copy event log files, you need to use 'Volume Shadow Copy Service'. I used [Shadow Copy](https://runtime.org/shadow-copy.htm):

```
Shadowcopy.exe C:\Windows\System32\winevt\Logs\*.* D:\logs\winevt /s
```

The next step is parsing the log with a Powershell script. 

Powershell scripts are disabled by default. In order to enable them enter this from the Powershell prompt:

```
powershell.exe Set-ExecutionPolicy unrestricted
```

The script combines a number of fields to create a unique "word" on which Word2Vec will be trained.

Example: 

```
system524informationmicrosoftwindowskernelpower 
```

This name consist of the log name, in this case "System", the event ID "524", the level “Information” and source “Microsoft Windows Kernel Power”. All ‘white space’ (spaces, underscores etc) are removed and all text is converted to lowercase.

The dataset looks like this:
```
TimeCreated,EventRecordID,Event
2021-03-12 21:28:22.470844+00:00,1,system12informationmicrosoftwindowskernelgeneral
```

The ‘EventRecordID’ is a unique sequence number in this particular event log file.
