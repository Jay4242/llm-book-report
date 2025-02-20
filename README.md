# llm-book-report


Trying to make an LLM do a chapter-by-chapter analysis of a book.


### llm-book-review.bash


This is a BASH script that tries to parse the chapters of the book and send them to the bot for review.

Depends on the chapters being marked as \[CHAPTER 1\], \[CHAPTER 2\] ... \[CHAPTER 10\], etc. otherwise it won't parse them properly.

May do a terrible job.


### llm-python-file.py


Sends a text file to the LLM.


Uses a `preprompt` and `postprompt` around the text to give the bot context about the file then reinforce the task you're asking of it.  


### llm-python-file-3.py


Sends three text files to the bot in the same fashion as `llm-python-file.py`
