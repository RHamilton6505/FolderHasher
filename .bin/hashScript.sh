cd ..
echo "Getting list of files..."
ls | tee .bin/files.txt                        #put all the names of files in one file
declare -i NUM_FILES=$(wc -l<.bin/files.txt)   #get the number of files
declare -i CURRENT_FILE=0                      #current file num being iterated thru..

while read line
do
  LINE_HASH=$(cat $line | sha512sum)
  ADD_HASHES="$FINAL_HASH $LINE_HASH"
  FINAL_HASH=$(echo $ADD_HASHES | sha512sum)
done < .bin/files.txt

echo checking hash...
CORRECT_HASH=$(cat .bin/hashFile.txt)
set $FINAL_HASH $CORRECT_HASH
echo $FINAL_HASH
echo $CORRECT_HASH

if [ "$FINAL_HASH" == "$CORRECT_HASH" ]
then
  echo "Hashes match!"
fi

if [ "$FINAL_HASH" != "$CORRECT_HASH" ]
then
  echo "Hashes don't match!"
fi
