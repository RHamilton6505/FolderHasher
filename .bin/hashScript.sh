cd ..
echo "Getting list of files..."
ls | tee .bin/files.txt
lines=$(wc -l<.bin/files.txt)
echo $lines
