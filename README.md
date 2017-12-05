# NuMetRRBS
## Data Analysis of Ovation RRBS Methyl-Seq Libraries

The Ovation RRBS Methyl-Seq System generates libraries compatible with Illumina sequencing platforms. After parsing the data by sample index, libraries must be trimmed prior to alignment as described below to remove adaptor sequence, low quality reads, and diversity bases. Ensure you have installed the most current version of `Trim Galore`, `Bismark`, `Bowtie2`, and Samtools prior to data analysis. Additional scripts used for data analysis are available through NuGEN Technical Support (techserv@nugen.com). Optional de-duplication can be performed after alignment to the reference genome following the instructions below.

## Adaptor and Quality Trimming

To accurately identify the diversity sequence and MspI `(C^CGG)` site it is important to first trim any adaptor sequence that may be present on the 3’ end of your reads. [Trim Galore](www.bioinformatics.babraham.ac.uk/projects/trim_galore/) works well for this purpose, but there may be other equivalent options available. Trim Galore will also trim some or all of a read due to low quality. Run the program with default parameters and do not use the --RRBS option.
Trim single end reads with the following command:

`trim_galore -a AGATCGGAAGAGC R1.FQ`

If you have paired-end reads, use this command instead:

`trim_galore --paired -a AGATCGGAAGAGC -a2 AAATCAAAAAAAC R1.FQ R2.FQ`

## Diversity Trimming and Filtering
Following adaptor and quality trimming and prior to alignment, the additional sequence added by the diversity adaptors must be removed from the data. This trimming is performed by a custom python script provided by NuGEN. To obtain this script, contact NuGEN Technical Support at techserv@nugen.com. The script removes any reads that do not contain an MspI site signature (YGG) at the 5’ end. For paired end data an MspI site signature is required at the 5’ end of both sequences. The script accepts as input one or two fastq file strings, given either as complete filenames or as a pattern in quotes. When a pattern is given, the script will find all the filenames matching a specified pattern according to the rules used by the Unix shell (*,?). You may access the help option of this script for more details (-h).


Example usage for single end reads after adaptor and quality trimming with a complete filename:

`python trimRRBSdiversityAdaptCustomers.py -1 sample_R1.fq`

with a pattern:

`python trimRRBSdiversityAdaptCustomers.py -1 '*R1.fq'`

Example usage for paired-end reads after adaptor and quality trimming with a complete filename:

`python trimRRBSdiversityAdaptCustomers.py -1 sample_R1.fq -2 sample_R2.fq`

with a pattern:

`python trimRRBSdiversityAdaptCustomers.py -1 '*R1.fq' -2 ‘*R2.fq’`

The script will generate new file(s) with `_trimmed.fq` appended to the filename. The reads will have been trimmed at the 5’ end to remove the diversity sequence (0–3 bases), and all reads should begin with YGG, where Y is C or T. On the 3’ end, 5 bases are trimmed from every read (6 bases are trimmed for paired-end to prevent alignment issues).
The trimmed fastq file should be used for downstream analysis including Bismark.

## Alignment to Genome
After trimming, the data can be aligned to the genome of interest. [Bismark](http://www.bioinformatics.babraham.ac.uk/projects/bismark/) is a tool that aligns bisulfite converted sequencing reads to the genome and also performs methylation calls in the same step. The program supports single and paired-end reads and both ungapped and gapped alignments. Other equivalent options may be available.

### To align single end reads:

`bismark --bowtie2 /location/bismark/genome/ R1_trimmed.FQ`

### For paired-end reads:

`bismark --bowtie2 /location/bismark/genome/ -1 R1_trimmed.FQ -2 R2_trimmed.FQ`

Note: Recent versions of Bismark automatically generate a BAM file instead of a SAM file. In order to perform the optional duplicate determination step, the resulting BAM file must be converted to a SAM file, or else run Bismark with option `--sam`. Continue with downstream data analysis or to unique molecule identification as described in the following section.

## Duplicate Determination with NuDup (Optional):
The N6 molecular tag is a novel approach to the unambiguous identification of unique molecules. Traditionally, PCR duplicates are identified in libraries made from randomly fragmented inserts by mapping inserts to the genome and discarding any paired end reads that share the same genomic coordinates. This approach doesn’t work for restriction digested samples, such as RRBS, because all fragments mapping to a genomic location will share the same ends. The Duplicate Marking tool utilizes information provided by the unique N6 sequence to discriminate between true PCR duplicates and independent adaptor ligation events to fragments with the same start site resulting in the recovery of more usable data. 
First, Bismark output files must be modified for input into NuDup using the following command:
strip_bismark_sam.sh bismarkout_stripped.sam

Note: Recent versions of Bismark automatically generate a BAM file instead of a SAM file. In order to use the stripping tool, the resulting BAM file must be converted to a SAM file, or else run Bismark with option `--sam`

Next, run NuDup using the modified SAM files as input:
For single end reads:

`python nudup.py –f index.fq –o outputname bismarkout_stripped.sam`

For paired-end reads:

`python nudup.py –2 –f index.fq –o outputname bismarkout_stripped.sam`

Continue with downstream data analysis.

Note: These commands assume that a 12-base index read was generated. If longer index reads were generated, contact NuGEN Technical Support.

## Diversity Trimming Examples

### Examples of Trimming the 5’ Ends of Forward Reads

Bases in blue denote sequence derived from the adaptor. In this example, the fragment was derived from the genomic sequence, starting and ending with MspI sites:

```
5’ CCGGAGTT…AAGGGCCGG 3’
3’ GGCCTCAA…TTCCCGGCC 5’
```

After MspI digestion:

```
5’ CGGAGTT…AAGGGC 3’
3’ CTCAA…TTCCCGGC 5’
```

After ligation to adaptors, both with three bases of diversity:
```
5’ RDDCGGAGTT…AAGGGCCGHHY 3’
3’ YHHGCCTCAA…TTCCCGGCDDR 5’
```

After bisulfite conversion and PCR amplification of the top strand:

```
5’ RDDYGGAGTT…AAGGGTCGHHY 3’
3’ YHHRCCTCAA…TTCCCAGCDDR 5’
```

Assuming the insert is smaller than the read length, the forward read after Trim Galore
is used to trim the adaptor from the 3’ end will be:

```
5’ RDDYGGAGTT…AAGGGTCGHHY 3’
```

The result of the NuGEN diversity trim of the forward read (if it's a single-end read)
will be:
```
5’ YGGAGTT…AAGGGT 3’
```

The reverse read after Trim Galore is used will be:
```
5’ RDDCGACCCTT…AACTCCRHHY 3’
```
The result of the NuGEN diversity trim of the reverse read:
```
5’ ACCCTT…AACT 3’
```

The adaptor can contain between 0 and 3 bases of diversity.

Tables 12–15 show how the script trims all types of adaptor variation.

```
(insert tables 11,12,13 from M01394v3 here)
```

## Effects of Read Length on Mapping Rate

The following data illustrates how read length affects mapping rates. An Ovation RRBS Methyl-Seq System library was prepared from IMR90 cell line DNA and sequenced on a HiSeq2500 in Rapid Run mode using 2X 100 nt paired end reads. The raw data was used in full, or trimmed as indicated, before processing first with [Trim Galore](www.bioinformatics.babraham.ac.uk/projects/trim_galore/) to remove adaptor sequence and low quality bases, and then with the NuGEN diversity trimming script. The resulting reads were then mapped to the hg19 human genome reference using [Bismark](www.bioinformatics.bbsrc.ac.uk/projects/bismark/).

Table 14 displays the percent of reads mapping uniquely and non-uniquely for single end reads of various lengths.

Table 15 presents the same metrics for paired end reads. 29 nt and 36 nt reads are shown to enable comparison to published RRBS data (29 nt single end reads — Boyle, et al. (2012) Genome Biol 13:R92. 36nt single end reads — Varley, et al. (2013) Genome Res 23:555). While some reports use modified reference genomes to reflect only expected MspI fragments for mapping, for this analysis reads were mapped to the entire, unmodified human reference genome.

```(insert tables 14 from M01394v3 here)```

In addition to mappability, you may also want to consider how read length affects CpG loci coverage. Many MspI fragments contain internal CpG's, so longer reads will sequence more CpGs. However, many MspI fragments are smaller than 100 bp, and even smaller than 50 bp. For these fragments, long sequencing reads, or paired end reads, provide no additional CpG data.

```(insert tables 15 from M01394v3 here)```
