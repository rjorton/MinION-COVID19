#!/bin/bash

#IFS=$'\n'

echo "artic_cvr_run.sh"
echo ""
echo "Reminder: you need to be in the artic ncov2019 env: conda activate artic-ncov2019"
echo "This simple script will use the current folder name as your run name"
echo "The current folder should have a folder called fastq with all the pass/fail fastq files in"
echo "This script should be run with one argument: the path to the corresponding fast5 folder, e.g."
echo "If a second argumnet is added (anything) the none sample will also be processed"
echo "./artic_cvr_run.sh /path/to/run/folder/fast5"
echo ""

donone=${2}

if [[ -z ${donone} ]];
then
	donone="no"
else
	donone="yes"
fi

myrun=${PWD##*/}
echo "Folder/Run Name = ${myrun}"

artic gather --min-length 400 --max-length 700 --prefix ${myrun} --directory ./fastq

artic demultiplex --threads 10 ${myrun}_pass.fastq

nanopolish index -s ${myrun}_sequencing_summary.txt -d $1 ${myrun}_pass.fastq

for file in *_pass-*.fastq
do
	sampTemp=${file##*_pass-}
	samp=${sampTemp%.*}
	none="none"

	if [ "$samp" != "$none" ] || [ "$donone" = "yes" ]; then
		echo "sample = ${samp} = ${file}"
		artic minion --normalise 200 --threads 10 --scheme-directory /home1/orto01r/miniconda3/artic-ncov2019/primer_schemes --read-file ${file} --nanopolish-read-file ${myrun}_pass.fastq nCoV-2019/V1 ${samp}
		weeSAM --bam ${samp}.sorted.bam --out ${samp}.weesam.txt --html ${samp} --overwrite
		samtools depth -a -d10000000 ${samp}.sorted.bam > ${samp}.sorted.bam.cov.txt
		R --vanilla --slave --args ${sName}.sorted.bam.cov.txt ${samp} < /home4/nCov/Richard/Ref/coverage_plot.R		
		samtools depth -a -d10000000 ${samp}.primertrimmed.sorted.bam > ${samp}.primertrimmed.sorted.bam.cov.txt
	fi
done


