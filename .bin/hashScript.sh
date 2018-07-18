cd ..
echo "Getting list of files and making hashes..."
ls | tee .bin/files.txt                        #put all the names of files in one file
declare -i NUM_FILES=$(wc -l<.bin/files.txt)   #get the number of files
declare -i CURRENT_FILE=1                      #current file num being iterated thru..

while read line
do
  touch $CURRENT_FILE.txt
  LINE_HASH=$(cat $line | sha512sum)
  echo $LINE_HASH | tee $CURRENT_FILE.txt
  mv $CURRENT_FILE.txt .hashes
  CURRENT_FILE=$CURRENT_FILE+1
done < .bin/files.txt


declare -i CURRENT_LEVEL=0
declare -i TOP_LEVEL=$(echo "l($NUM_FILES)/l(2)" | bc -l | cut -f1 -d".")

while [ $CURRENT_LEVEL -lt $TOP_LEVEL ]
do

  CURRENT_HASH=1
  CURRENT_FILE=1

  while [ $CURRENT_HASH -lt $((NUM_FILES / 2 + 1)) ]
  do
    NEW_HASH_POS1=$((CURRENT_HASH * 2))
    NEW_HASH_POS2=$((CURRENT_HASH * 2 - 1))
    echo $NEW_HASH_POS1
    echo $NEW_HASH_POS2

    HASH_CONCAT="$(cat .hashes/$NEW_HASH_POS1.txt) $(cat .hashes/$NEW_HASH_POS2.txt)"
    rm .hashes/$NEW_HASH_POS1.txt
    rm .hashes/$NEW_HASH_POS2.txt

    echo $HASH_CONCAT | sha512sum | tee .hashes/$CURRENT_HASH.txt



    CURRENT_HASH=$((CURRENT_HASH + 1))
  done

  NUM_FILES=$((NUM_FILES / 2))
  CURRENT_LEVEL=$((CURRENT_LEVEL + 1))

done


echo checking hash...

FINAL_HASH=$(cat .hashes/1.txt | cut -d '-' -f 1)
CORRECT_HASH=$(cat .bin/hashFile.txt | cut -d '-' -f 1)

echo
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
fi
