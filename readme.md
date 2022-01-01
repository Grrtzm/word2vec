## Using Word2Vec for ‘Anomaly Detection’ in Windows Eventlogs
### _This is just a proof of concept, not a final product!_
---
I used two different implementations of Word2Vec; [the popular Gensim version](https://github.com/Grrtzm/word2vec/blob/main/windows_eventlog_anomaly_detection_with_gensim_word2vec.ipynb) and [one built in Tensorflow](https://github.com/Grrtzm/word2vec/blob/main/windows_eventlog_anomaly_detection_with_tensorflow_word2vec.ipynb).
The goal was to reproduce the same results in both versions, but i could not exactly reproduce the same results.
Even more remarkable: After every training you get different 'Top 10' results, it varies every time. This applies for both the Gensim as well as the Tensorflow version.

The Gensim version (based on gensim 4.12) is a bit of a black box. Tweaking the hyperparameters didn't give me better results.
The Tensorflow version works better for me. Take a look at the results at the bottom of the Notebook.

Both were inspired on tutorials. You can find the links in the headers of my Jupyter Notebooks.

-----
## Instructions for use
-----

You can't just copy event log files, they are locked by the operating system.

To copy event log files, you need to use 'Volume Shadow Copy Service'.

I used [Shadow Copy](https://runtime.org/shadow-copy.htm):

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
