#!/bin/bash
set -e
set -o pipefail
set -u

trap "echo ERROR" ERR

cd "$(dirname "$0")"
HERE="$(pwd)"

#cleanup from any previous runs
rm -r ../*/linear_spectrograms 2> /dev/null || true
rm -r ../*/spectrograms 2> /dev/null || true

cp /dev/null train.txt
cp /dev/null val.txt

rm xaa 2> /dev/null || true
rm xab 2> /dev/null || true

#add in what little 1st person speaker audio I have
cat ma-split-annotated.txt | sed 's|durbin-feeling|01-chr|' | sed 's|ma-split/|../cherokee/ma-split/|'  | shuf > tmp.txt
split -l $[ $(wc -l tmp.txt|cut -d " " -f1) * 95 / 100 ] tmp.txt
cat xaa >> train.txt
cat xab >> val.txt

#sam hider
cat ../cherokee-audio/sam-hider/train.txt | sed 's|wav/|../cherokee-audio/sam-hider/wav/|g' >> train.txt
cat ../cherokee-audio/sam-hider/val.txt | sed 's|wav/|../cherokee-audio/sam-hider/wav/|g' >> val.txt

#create dummy voices using random DF voices for later replacement with other speakers
#always be sure to not use an existing voice id from another data set!
for i in $(seq 3 1 20); do
	j=$(printf "%02d" "$i")
	shuf xaa | tail -n 1 | sed "s/01-chr/$j-chr/g" >> train.txt
	shuf xab | tail -n 1 | sed "s/01-chr/$j-chr/g" >> val.txt
done

#replace the synthetic speaker as well, as the speaker count must REMAIN THE SAME with the SAME IDs!
grep '|02-chr|' train.txt | shuf | tail -n 1 | sed 's/02-chr/01-syn-chr/g' > xaa
grep '|02-chr|' val.txt | shuf | tail -n 1 | sed 's/02-chr/01-syn-chr/g' > xab

cat xaa >> train.txt
cat xab >> train.txt


comvoi="comvoi-subset.txt"
cat ../comvoi_clean/all.txt > "$comvoi"

cut -f 1 -d '|' "$comvoi" > tmp1 #id
cut -f 2 -d '|' "$comvoi" > tmp2 #speaker
cut -f 3 -d '|' "$comvoi" > tmp3 #language
cut -f 4 -d '|' "$comvoi" > tmp4 #source wav
cut -f 5 -d '|' "$comvoi" > tmp5 #text
cut -f 999 -d '|' "$comvoi" > blank

#point to the original data the common voice data was pulled from
sed -i 's|^|../comvoi_clean/|' tmp4

paste -d "-" tmp2 tmp3 > tmp6

paste -d "|" tmp1 tmp6 tmp3 tmp4 blank blank tmp5 blank | shuf > tmp.txt 

split -l $[ $(wc -l tmp.txt|cut -d " " -f1) * 95 / 100 ] tmp.txt
cat xaa >> train.txt
cat xab >> val.txt

rm tmp? tmp?? blank 2> /dev/null || true
rm xaa xab

echo "Done"