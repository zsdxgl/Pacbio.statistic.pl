# Pacbio.statistic.pl

#What to deal with

count count the subreads
convert the bam file to fasta file

#How to use

1. ./Pacbio.statistic.pl

        version 1.0

        -p: path to the top directory that including the bam files of subread
        -h: help

        dependence: R library, IDPmisc, ggplot2

2. ls ./Pacbio/

        r54214_20190107_084045_1_A01

        r54221_20181221_083108_1_A01

3. ./Pacbio.statistic.pl -p fileto/Pacbio/

#Output

1. convert subreads.bam to subreads.fasta
2. count the number of subreads
  Pacbio1.out: 
  subread length\trepeat number in this polymerase read
  
  Pacbio2.out: sorted subread
  accumulated subread number\taccumulated effective subread length\trepeat number in this polymerase read
 3. Pacbio1.tif
 4. Pacbio2.tif
