# MinION-COVID19
### MinION nCoV COVID19 data processing commands for frankenstein/alpha - using guppy and ARTIC

#### Guppy Base Calling
Ideally everything would be done on the machine running MinKnow and the MinION (to avoid data transfers everywhere), but if the machine is incapable of basecalling quickly (i.e. it doesn't have a GPU and Linux) then the below is one way.

Transfer the MinKnow fast5 data folder to frankenstein (the HPC cluster at the [Scottish Centre for Macromolecular Imaging](https://www.gla.ac.uk/researchinstitutes/iii/cvr/scmi/)) for GPU basecalling, e.g. scp or rysnc:

```
rsync -e ssh -avr /path/to/fast5/folder username@frankenstein.cvr.gla.ac.uk:~/destination/folder/
```

Login to frankenstein either from within campus or via the VPN:

```
ssh username@frankenstein.cvr.gla.ac.uk
```

Basecalling must be done on one of the GPU nodes (nodes 114 - 120) on frankenstein. However, node114 (with 8 Tesla K80s) is unsuitable (gives a CUDA_ERROR_NO_BINARY_FOR_GPU), so any one of nodes 115 - 120 can be used which have 4 Tesla P100s each.

To request/reserve a gpu node for basecalling you tell the scheduler what resources you need: here you are asking for 1 process on a GPU node (excluding node 114), -K means that when you are finished the salloc process will be killed (thanks to Michaela Conley for this):

```
salloc -n1 -K1 --exclude=node114 -p gpu
```

You should see an output with your jobid - make a note of it:

```
salloc: Granted job allocation <jobid>
```

Now see what GPU node has been designated for the job:

```
echo $SLURM_JOB_NODELIST
```

This will output something like node115, so now we ssh into the node - assuming it is node115:

```
ssh node115
```

You can view the graphics card details of the node with the command:

```
nvidia-smi
```

And also check if anyone else is logged into the node with:

```
w
```

Now we can use [guppy](https://community.nanoporetech.com/downloads) to do the basecalling. This is not installed on frankenstein, but can be downloaded from the [nanopore website](https://community.nanoporetech.com/downloads) (login required) and simply copied into your home directory. A copy is located in my home directory in ~orto01r/ont-guppy

-x cuda:0:100% - this command will use all (100%) of the first (0) graphics card for base calling:

```
~orto01r/ont-guppy/bin/guppy_basecaller -i /path/to/fast5/folder -s /path/to/output/fastq/folder --flowcell FLO-MIN106 --kit SQK-LSK109 --qscore_filtering --min_qscore 7 -x cuda:0:100% -r
```

-x auto - it seems slightly quicker to use the auto option (although nowhere near 4 times as quick, given there are 4 GPUs):

```
~orto01r/ont-guppy/bin/guppy_basecaller -i /path/to/fast5/folder -s /path/to/output/fastq/folder --flowcell FLO-MIN106 --kit SQK-LSK109 --qscore_filtering --min_qscore 7 -x auto -r
```

You will need to change the flowcell and kit to whatever was used, an alternative to the flowcell/kit is to use one of the provided config files (you will need to select the correct config file for your kit/flowcell). The default is to use the high accuracy mode (hac) config file, this can be overridden to use the fast (lower accuracy mode) config file. An example of specifying a config file:

```
~orto01r/ont-guppy/bin/guppy_basecaller -i /path/to/fast5/folder -s /path/to/output/fastq/folder --config ~orto01r/ont-guppy/data/dna_r9.4.1_450bps_fast.cfg --qscore_filtering --min_qscore 7 -x auto -r
```

Depending on the size of the dataset this could take a few hours - but it does give you a 0-100% progress bar on the terminal as it is going so you can estimate how long it will take. There are many options that could be tweaked to potentially speed things up, (like chunk size, chunks per runner, etc) some good sites I found are:

* [August-2019-consensus-accuracy-update](https://github.com/rrwick/August-2019-consensus-accuracy-update)
* [Jetson Xavier basecalling notes](https://gist.github.com/sirselim/2ebe2807112fae93809aa18f096dbb94)
* [Guppy GPU benchmarking](https://esr-nz.github.io/gpu_basecalling_testing/gpu_benchmarking.html)

When the job is finished, the fastq folder will be populated with lots of guppy log files, a sequencing summary file, and the fastq pass and fail (q score filter) folders where all the output fastq files are (like the fast5 files there are lots of fastq files).

Copy the fastq back over to alpha (or wherever you want) via scp/rsync, e.g.

```
rsync -e ssh -avr /path/to/fastq/folder username@alpha.cvr.gla.ac.uk:~/destination/folder/
```

Now logout of the node:

```
logout
```

And now kill your job:

```
scancel jobid
```

Double check your job is not in the queue anymore:

```
squeue
```

And check that the salloc process has finished:

```
ps
```

Now logout of frankenstein:

```
logout
```

Probably best to delete all the data from frankenstein when done as everything should now be on alpha. If you have a local GPU it could well be quicker to use that rather than transferring data back and forth.

#### Consensus generation

To filter, porchop demultiplex, align, primer trim and call the consensus, we use the ARTIC nCoV-2019 environment and instructions. Full instructions are available here:

[ARTIC nCoV-2019](https://artic.network/ncov-2019)

These requires access to both the fastq and fast5 (for nanopolish) files. But briefly:

You will need to install the [ARTIC nCoV-2019 conda environment](https://artic.network/ncov-2019/ncov2019-it-setup.html). After installing, activate it for your login session:

```
conda activate artic-ncov2019
```

First, combine all the fastq reads into one file and filter out reads out of the expected amplicon range:

```
artic gather --min-length 400 --max-length 700 --prefix myrun --directory /path/to/fastq/folder/
```

This creates a my_run_all.fastq, myrun_fail.fastq and myrun_pass.fastq files, along with a myrun_sequencing_summary.txt

Second, demultiplex the reads and remove mid-adapter reads using porechop (on alpha this can take a while if using all of the run data):

```
artic demultiplex --threads 10 myrun_pass.fastq
```

Third, index the reads for nanopolish:

```
nanopolish index -s myrun_sequencing_summary.txt -d /path/to/fast5/folder myrun_pass.fastq
```

Fourth, align the reads, trim the primers, call variants, call and polish the consensus:

If you have not used barcodes all the reads will be in the -none.fastq file and none should be used for sample name

```
artic minion --normalise 200 --threads 10 --scheme-directory ~/artic-ncov2019/primer_schemes --read-file myrun_pass-none.fastq --nanopolish-read-file myrun_pass.fastq nCoV-2019/V1 none
```

The consenus sequence will be:

```
none.consensus.fasta
```

If you have used barcodes you will need to run the below command for each barcode NB01, NB02 etc etc:
```
artic minion --normalise 200 --threads 10 --scheme-directory ~/artic-ncov2019/primer_schemes --read-file myrun_pass-NB01.fastq --nanopolish-read-file myrun_pass.fastq nCoV-2019/V1 NB01
```

```
artic minion --normalise 200 --threads 10 --scheme-directory ~/artic-ncov2019/primer_schemes --read-file myrun_pass-NB02.fastq --nanopolish-read-file myrun_pass.fastq nCoV-2019/V1 NB02
```

The [ARTIC nCoV-2019 bioinformatics sop](https://artic.network/ncov-2019/ncov2019-bioinformatics-sop.html) instructions are a lot more detailed.

Deactivate the conda environment session before logging out:

```
conda deactivate
```

#### Data
Data from previous runs is available on alpha in:

```
/home1/illumina/MinION/ncov_MinION/
```

#### Useful web links
* [ARTIC Network nCoV-2019](https://artic.network/ncov-2019)
* [ARTIC Network GitHub](https://github.com/artic-network)
* [Virological](http://virological.org)
* [CoV-GLUE](http://cov-glue.cvr.gla.ac.uk/)
* [GISAID](https://www.gisaid.org)
* [Nanopore Downloads](https://community.nanoporetech.com/downloads)
* [MN908947](https://www.ncbi.nlm.nih.gov/nuccore/MN908947)

#### Some issues
* When running the artic demultiplex command on my laptop with all the data from a run, the process ended up getting killed. Am pretty sure this was due to running out of RAM (I had 16GB RAM), monitoring this step on alpha it built up to using 90GB of RAM.
* The Export Reads function within rampart was not working - gave an error - raised an issue on github
* When running rampart, details of each read's assigned sample barcode and mapping co-ordinates (for the actual visualisations) are located in the annotations/ folder by default. If starting a new rampart run/visualisation (i.e. pointing to a new fastq folder), these existing annotations do not get cleared, so the new run's data will be added ontop of the old run's data (so the visualisation will utlise both data sets). The ~/annotations/ folder seems quite useful for later on so make a copy of it when it is finished, and delete it when done so the next rampart viz can start afresh.

#### Random command dump

```
cd ~/x5/batch5/

guppy_basecaller --input_path ./fast5 --save_path ./fastq --flowcell FLO-MIN106 --kit SQK-LSK109 -x cuda:0:100%

rampart --protocol ~/artic-ncov2019/rampart --basecalledPath ./fastq/pass/

http://localhost:3000

artic gather --min-length 400 --max-length 700 --prefix batch5 --directory ./fastq

artic demultiplex --threads 10 batch5_pass.fastq

nanopolish index -s batch5_sequencing_summary.txt -d ./fast5/ batch5_pass.fastq

artic minion --normalise 200 --threads 10 --scheme-directory ~/artic-ncov2019/primer_schemes --read-file batch5_pass-NB01.fastq --nanopolish-read-file batch5_pass.fastq nCoV-2019/V1 NB01

artic minion --normalise 200 --threads 10 --scheme-directory ~/artic-ncov2019/primer_schemes --read-file batch5_pass-NB02.fastq --nanopolish-read-file batch5_pass.fastq nCoV-2019/V1 NB02

artic minion --normalise 200 --threads 10 --scheme-directory ~/artic-ncov2019/primer_schemes --read-file batch5_pass-none.fastq --nanopolish-read-file batch5_pass.fastq nCoV-2019/V1 none
```
