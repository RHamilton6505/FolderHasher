cd ..
PARENT_PATH=$(pwd)
BIN_PATH=$(echo $PARENT_PATH/.bin)
HASHF_PATH=$(echo $PARENT_PATH/.hashes)

echo "What is the folder you'd like to hash?"
read HASH_PATH                                          #gets the path to the folder that will be hashed
cd $HASH_PATH                                           #changes user to the correct directory
echo "Getting list of files and making hashes..."

ls | sed 's/ /\\ /g' | tee $BIN_PATH/files.txt          #put all the names of files in one file
declare -i NUM_FILES=$(wc -l < $BIN_PATH/files.txt)     #get the number of files
declare -i CURRENT_FILE=1                               #current file num being iterated thru..
declare -i FILES_HASHED=$NUM_FILES

while read line                                         #loop, while there are still files, it hashes
do
  touch $CURRENT_FILE.txt
  LINE_HASH=$(cat $line | sha512sum)
  echo $LINE_HASH | tee $CURRENT_FILE.txt
  mv $CURRENT_FILE.txt $HASHF_PATH
  CURRENT_FILE=$CURRENT_FILE+1
done < $BIN_PATH/files.txt

#these four lines are what setup the tree in our program

declare -i CURRENT_LEVEL=0
declare -i TOP_LEVEL=$(echo "l($NUM_FILES)/l(2)" | bc -l | cut -f1 -d".")
declare -i FILE_EXP=$(echo "2^$TOP_LEVEL" | bc -l)
declare -i OVERFLOW=$((NUM_FILES-FILE_EXP))



if [ "$OVERFLOW" -gt 0 ]
then

  CURRENT_HASH=1
  
  #while there are more than one files in our folder, it will continue to combine the files and rehash them
  #this is set up for if there is an odd number
  
  while [ $CURRENT_HASH -lt $((OVERFLOW + 1)) ]
  do
    NEW_HASH_POS1=$((CURRENT_HASH * 2))
    NEW_HASH_POS2=$((CURRENT_HASH * 2 - 1))
    # echo $NEW_HASH_POS1
    # echo $NEW_HASH_POS2
    HASH_CONCAT="$(cat $HASHF_PATH/$NEW_HASH_POS1.txt) $(cat $HASHF_PATH/$NEW_HASH_POS2.txt)"
    rm $HASHF_PATH/$NEW_HASH_POS1.txt
    rm $HASHF_PATH/$NEW_HASH_POS2.txt

    echo $HASH_CONCAT | sha512sum | tee $HASHF_PATH/$CURRENT_HASH.txt

    CURRENT_HASH=$((CURRENT_HASH + 1))
  done

  CURRENT_HASH=$((CURRENT_HASH + OVERFLOW))
  echo currenthash $CURRENT_HASH
  echo overflow $OVERFLOW

  while [ $CURRENT_HASH -lt $((NUM_FILES + 1)) ]
  do
    NEW_POS=$((CURRENT_HASH - OVERFLOW))
    mv $HASHF_PATH/$CURRENT_HASH.txt $HASHF_PATH/$NEW_POS.txt
    echo
    CURRENT_HASH=$((CURRENT_HASH + 1))
  done

  NUM_FILES=$FILE_EXP

fi

#does the same thing as loop above, but for even numbers

while [ $CURRENT_LEVEL -lt $TOP_LEVEL ]
do

  CURRENT_HASH=1
  CURRENT_FILE=1

  while [ $CURRENT_HASH -lt $((NUM_FILES / 2 + 1)) ]
  do
    NEW_HASH_POS1=$((CURRENT_HASH * 2))
    NEW_HASH_POS2=$((CURRENT_HASH * 2 - 1))

    HASH_CONCAT="$(cat $HASHF_PATH/$NEW_HASH_POS1.txt) $(cat $HASHF_PATH/$NEW_HASH_POS2.txt)"
    rm $HASHF_PATH/$NEW_HASH_POS1.txt
    rm $HASHF_PATH/$NEW_HASH_POS2.txt

    echo $HASH_CONCAT | sha512sum | tee $HASHF_PATH/$CURRENT_HASH.txt



    CURRENT_HASH=$((CURRENT_HASH + 1))
  done

  NUM_FILES=$((NUM_FILES / 2))
  CURRENT_LEVEL=$((CURRENT_LEVEL + 1))

done

#tests to make sure the hash is correct

echo checking hash...

clear

FINAL_HASH=$(cat $HASHF_PATH/1.txt | cut -d '-' -f 1)
CORRECT_HASH=$(cat $BIN_PATH/hashFile.txt | cut -d '-' -f 1)

echo Hashed $FILES_HASHED files!
echo
echo CALCULATED HASH $FINAL_HASH
echo
echo RECORDED HASH $CORRECT_HASH


if [ "$FINAL_HASH" == "$CORRECT_HASH" ]
then
  echo "Hashes match!"
fi

if [ "$FINAL_HASH" != "$CORRECT_HASH" ]
then
  echo "Hashes don't match!"
  echo "Would you like to save this new hash as the new hash (y/n)?"
  read ANSWER
  if [ $ANSWER == y ]
  then
    echo "$FINAL_HASH-" > $BIN_PATH/hashFile.txt
    echo "Hash changed!"
  fi
fi
