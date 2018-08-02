cd .. #change directory to the home directory of the project
PARENT_PATH=$(pwd)
BIN_PATH=$(echo $PARENT_PATH/.bin) # Path to the script
HASHF_PATH=$(echo $PARENT_PATH/.hashes) # Path to where the "node files" are
echo "What is the folder you'd like to hash?"
read HASH_PATH
cd $HASH_PATH
echo "Getting list of files and making hashes..."

# The following creates a file with the names of all files being hashed
ls | sed 's/ /\\ /g' | tee $BIN_PATH/files.txt                        #put all the names of files in one file
declare -i NUM_FILES=$(wc -l < $BIN_PATH/files.txt)   #get the number of files
declare -i CURRENT_FILE=1                      #current file num being iterated thru..
declare -i FILES_HASHED=$NUM_FILES

# The following block creates a file containing the hash, and moves it to the hash directory
while read line
do
  touch $CURRENT_FILE.txt # creates a new file for the given file hash
  LINE_HASH=$(cat $line | sha512sum) # create hash
  echo $LINE_HASH | tee $CURRENT_FILE.txt # writes hash to file
  mv $CURRENT_FILE.txt $HASHF_PATH # moves file to .hashes directory
  CURRENT_FILE=$CURRENT_FILE+1
done < $BIN_PATH/files.txt


declare -i CURRENT_LEVEL=0
declare -i TOP_LEVEL=$(echo "l($NUM_FILES)/l(2)" | bc -l | cut -f1 -d".") # the amount of levels
declare -i FILE_EXP=$(echo "2^$TOP_LEVEL" | bc -l) # the amount of 2^n nodes
declare -i OVERFLOW=$((NUM_FILES-FILE_EXP)) # the amount of files that arent 2^n


# The following block is used to deal with overflow...
# it works by concatenating the overflow so that there
# is a 2^n structure
if [ "$OVERFLOW" -gt 0 ]
then

  CURRENT_HASH=1

  while [ $CURRENT_HASH -lt $((OVERFLOW + 1)) ]
  do
    NEW_HASH_POS1=$((CURRENT_HASH * 2)) # goes to the second item and creates a hash
    NEW_HASH_POS2=$((CURRENT_HASH * 2 - 1)) # goes to the item goes to the item before and hashes it
    HASH_CONCAT="$(cat $HASHF_PATH/$NEW_HASH_POS1.txt) $(cat $HASHF_PATH/$NEW_HASH_POS2.txt)" # concatenate the hashes
    rm $HASHF_PATH/$NEW_HASH_POS1.txt # remove files from working directory
    rm $HASHF_PATH/$NEW_HASH_POS2.txt

    echo $HASH_CONCAT | sha512sum | tee $HASHF_PATH/$CURRENT_HASH.txt # make a new hash file

    CURRENT_HASH=$((CURRENT_HASH + 1))
  done

  CURRENT_HASH=$((CURRENT_HASH + OVERFLOW))
  echo currenthash $CURRENT_HASH
  echo overflow $OVERFLOW

  # the following block moves the hash files that arent overflow to their correct numeric pos
  while [ $CURRENT_HASH -lt $((NUM_FILES + 1)) ]
  do
    NEW_POS=$((CURRENT_HASH - OVERFLOW)) # calculate what the new position of the hash is
    mv $HASHF_PATH/$CURRENT_HASH.txt $HASHF_PATH/$NEW_POS.txt # renames file
    echo
    CURRENT_HASH=$((CURRENT_HASH + 1))
  done

  NUM_FILES=$FILE_EXP # the number of files is now the 2^n value

fi

# The following consolidates the tree to one hash
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

# the following is used to check for correctness then ask user if it wants to be stored
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
  echo
  echo "Hashes match!"
fi

if [ "$FINAL_HASH" != "$CORRECT_HASH" ]
then
  echo
  echo "Hashes don't match!"
  echo "Would you like to save this new hash as the new hash (y/n)?"
  read ANSWER
  if [ $ANSWER == y ]
  then
    echo "$FINAL_HASH-" > $BIN_PATH/hashFile.txt
    echo "Hash changed!"
  fi
fi
