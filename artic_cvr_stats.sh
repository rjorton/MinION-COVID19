#!/bin/bash

#IFS=$'\n'

myrun=${PWD##*/}

echo "artic_cvr_stats.sh"
echo "This is a simple script to count the number of reads passing through each step of the artic pipeline"
echo "It relies on you having used the folderName for your runName - as in artic_cvr_run.sh"
echo "It also relies on the guppy pass/fail reads being in ./fastq/pass and ./fastq/fail folders"
echo ""
echo "Run name = ${myrun}"

donone=${1}

if [[ -z ${donone} ]];
then
	donone="no"
else
	donone="yes"
fi

rm -f ${myrun}_cvr_stats.txt
touch ${myrun}_cvr_stats.txt

echo "Counting guppy pass reads"
totalPassReads=0
for fastq in ./fastq/pass/*.fastq
do
	reads=$(expr `(wc -l ${fastq} |cut -f1 -d " ")` / 4)
	totalPassReads=$((totalPassReads + reads))
done

echo "Counting guppy fail reads"
totalFailReads=0
for fastq in ./fastq/fail/*.fastq
do
        reads=$(expr `(wc -l ${fastq} |cut -f1 -d " ")` / 4)
        totalFailReads=$((totalFailReads + reads))
done

totalReads=$((totalPassReads + totalFailReads))
passProp=`echo "$totalPassReads $totalReads" | awk '{printf "%.2f", $1/$2*100}'`
failProp=`echo "$totalFailReads $totalReads" | awk '{printf "%.2f", $1/$2*100}'`

echo "Guppy total reads=${totalReads}=100" >> ${myrun}_cvr_stats.txt
echo "Guppy fail reads=${totalFailReads}=${passProp}" >> ${myrun}_cvr_stats.txt
echo "Guppy pass reads=${totalPassReads}=${failProp}"  >> ${myrun}_cvr_stats.txt

reads=$(expr `(wc -l ${myrun}_pass.fastq |cut -f1 -d " ")` / 4)
gatherProp=`echo "$reads $totalReads" | awk '{printf "%.2f", $1/$2*100}'`
echo "${myrun}_pass.fastq=${reads}=${gatherProp}" >> ${myrun}_cvr_stats.txt

sampleReads=0
mappedReads=0

for file in *_pass-NB*.fastq *_pass-none.fastq
do
	sampTemp=${file##*_pass-}
	samp=${sampTemp%.*}
	none="none"

	if [ "$samp" = "$none" ] && [ "$donone" = "no" ]; then
		echo "Processing none = ${file}"
		reads=$(expr `(wc -l ${file} |cut -f1 -d " ")` / 4)
		echo "${file}=${reads}" >> ${myrun}_cvr_stats.txt
	else
		echo "Processing sample = ${samp} = ${file}"
		reads=$(expr `(wc -l ${file} |cut -f1 -d " ")` / 4)
		sampleReads=$((sampleReads + reads))
		echo "${file}=${reads}" >> ${myrun}_cvr_stats.txt
		reads=$(samtools view -c -F4 -F256 -F2048 ${samp}.sorted.bam)
		mappedReads=$((mappedReads + reads))
		echo "${samp}.sorted.bam mapped=${reads}" >> ${myrun}_cvr_stats.txt
		reads=$(samtools view -c -f4 ${samp}.sorted.bam)
                echo "${samp}.sorted.bam unmapped=${reads}" >> ${myrun}_cvr_stats.txt
		#bases=$(expr `samtools stats ${samp}.sorted.bam | grep "bases mapped (cigar):" | cut -f 3`)
		#avcov=`(echo "$bases 29903" | awk '{printf "%.2f", $1/$2}')`
		avcov=`(tail -n1 ${samp}.weesam.txt | cut -f 8)`
		echo "${samp}.sorted.bam avcov=${avcov}" >> ${myrun}_cvr_stats.txt
		ns=$(expr `grep -v ">" ${samp}.consensus.fasta | tr '[:lower:]' '[:upper:]' | tr -cd 'N' | wc -c`)
		concov=`echo "$ns 29903" | awk '{printf "%.2f", 100-$1/$2*100}'`
		echo "${samp}.consensus.fasta=${concov}" >> ${myrun}_cvr_stats.txt
	fi
done

echo ""
sampleProp=`echo "$sampleReads $totalReads" | awk '{printf "%.2f", $1/$2*100}'`
echo "Total demultiplexed reads=${sampleReads}=${sampleProp}" >> ${myrun}_cvr_stats.txt

mappedProp=`echo "$mappedReads $totalReads" | awk '{printf "%.2f", $1/$2*100}'`
echo "Total mapped reads=${sampleReads}=${mappedProp}" >> ${myrun}_cvr_stats.txt
