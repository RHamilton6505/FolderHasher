echo "Would you like to generate a large folder (y/n)?"
#finds out if user wants a larger file
read CHOICE
declare -i FOLDER_SIZE
declare -i CURRENT_FILE=0

cd ..
#if yes, generates more files
if [ $CHOICE == y ]
then
  FOLDER_SIZE=1000
fi

#if no it stays the same
if [ $CHOICE == n ]
then
  FOLDER_SIZE=4
fi

#creates all the text files
while [[ CURRENT_FILE -lt FOLDER_SIZE ]]; do
  touch file$CURRENT_FILE.txt
  CURRENT_FILE=$(($CURRENT_FILE+1))
done
cd .bin
echo "Done!"
