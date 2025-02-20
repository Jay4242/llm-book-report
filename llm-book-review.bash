#!/bin/bash

#Grab epub file from first parameter.
epub="$1"

#User input for the title.
read -p "What is the book title?: " title

#Set System Prompt
system_prompt="You are a literary genius."

#Set global temperature for the bot.
temp="0.7"

#Set Base Directory.
base="/dev/shm/llm-book-review" || exit 1

#Create directories in base directory.
mkdir -p "${base}" || exit 1
mkdir -p "${base}/character-summaries"
mkdir -p "${base}/chapter-summaries"
mkdir -p "${base}/chapters"

#Convert the epub to markdown.
pandoc -f epub -t markdown -o "${base}/book.md" "${epub}"

#Move to the working directory.  Or exit because something went wrong if we can't cd there.
cd "${base}" || exit 1

#Detect final chapter.
let fchapter=$(grep -i "\[.*CHAPTER .*\]" "${base}/book.md" | tail -n 1 | sed -e 's/].*//g' -e 's/.* //g')

#Loop through the chapters.
for chapter in `seq 1 ${fchapter}` ; do

   #Test if we're on the last chapter.
   if [[ "${chapter}" -lt "${fchapter}" ]] ; then

      #If we're not on the last chapter, carve out current chapter to N+1 chapter.

      #Set a 'next chapter' variable, 'nchapter'.
      let nchapter=${chapter}+1

      #Carve out the current chapter into a new markdown document.
      sed -n "/\[.*CHAPTER ${chapter}\]/,/\[.*CHAPTER ${nchapter}\]/p" "${base}/book.md" > "${base}/chapters/chapter_${chapter}.md"
   else
      #Else we're on the last chapter?  We dump the rest of the book.
      sed -n "/\[.*CHAPTER ${chapter}\]/,//p" "${base}/book.md" > "${base}/chapters/chapter_${chapter}.md"
   fi

   #The first chapter has some special conditions.
   if [[ "${chapter}" -eq "1" ]] ; then

      #We're on the first chapter.  Can start from the beginning with no previous chapter or character summaries.
      llm-python-file.py "${base}/chapters/chapter_${chapter}.md" "${system_prompt}" "The following is \`Chapter ${chapter}\` of the book \`${title}\`." "Write a bulletpoint character summary for the characters in \`Chapter ${chapter}\`. Do not include any explanation only the bulletpoint character summaries.  Write the summaries with the intent of using them to keep track of the characters of the story in future chapters." "${temp}" | tee "${base}/character-summaries/chapter_${chapter}.md"
      llm-python-file.py "${base}/chapters/chapter_${chapter}.md" "${system_prompt}" "The following is \`Chapter ${chapter}\` of the book \`${title}\`." "Write a synopsis for the story so far based on \`Chapter ${chapter}\`.  Do not include any explanation.  Write the synopsis with the intent of using it to keep track of the story as we read future chapters." "${temp}" | tee "${base}/chapter-summaries/chapter_${chapter}.md"

   else

      #Set the last chapter to lchapter.
      let lchapter=${chapter}-1

      #We are not on the first chapter.  We need to load in the previous chapter & character summaries when considering the chapter.
      llm-python-file-3.py "${system_prompt}" "${base}/character-summaries/chapter_${lchapter}.md" "The following are the current \`character summaries\` for the book \`${title}\` up to \`Chapter ${lchapter}\`." "${base}/chapter-summaries/chapter_${lchapter}.md" "The following is the current \`story synopsis\` for the book \`${title}\` up to \`Chapter ${lchapter}\`." "${base}/chapters/chapter_${chapter}.md" "The following is \`Chapter ${chapter}\` of the book \`${title}\`." "Write a bulletpoint character summary for all the characters in \`${title}\` so far.  Do not include any explanation only the bulletpoint character summaries.  Write the summaries with the intent of using them to keep track of the characters of the story in future chapters." "${temp}" | tee "${base}/character-summaries/chapter_${chapter}.md"
      llm-python-file-3.py "${system_prompt}" "${base}/character-summaries/chapter_${lchapter}.md" "The following are the current \`character summaries\` for the book \`${title}\` up to \`Chapter ${lchapter}\`." "${base}/chapter-summaries/chapter_${lchapter}.md" "The following is the current \`story synopsis\` for the book \`${title}\` up to \`Chapter ${lchapter}\`." "${base}/chapters/chapter_${chapter}.md" "The following is \`Chapter ${chapter}\` of the book \`${title}\`." "Write a \`story synopsis\` for the entire story of \`${title}\` so far.  Do not include any explanation, only the synopsis of the story so far.  Write the \`story synopsis\` with the intent of using them to keep track of the story in future chapters." "${temp}" | tee "${base}/chapter-summaries/chapter_${chapter}.md"


   fi

done
