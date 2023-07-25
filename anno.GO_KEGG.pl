#!/usr/bin/perl
use strict;
use Getopt::Long;
use Cwd;
use FindBin qw($Bin);
# $Bin为当前路径
use lib '/home/yangfan/Data/Bin/perl_script_my/final/';
use yangfan;
use Statistics::Descriptive;
use List::Util qw(shuffle);
#fuzzy_pattern($x,1);
my %opts;
my $program=`basename $0`;
chomp $program;
my $usage=<<USAGE; #******* Instruction of this program *********# 

Program : input gene name

Usage: .pl [gene name file] -o [out.name]
	-i			gene name column [1]
	-h			header or not [0]
	-p			pvalue cutoff [1]
	-q			qvalue cutoff [1]
	-o			out name
	-help			output help information

USAGE

GetOptions(\%opts, "l:s", "b:s", "o:s", "u:s", "i:s", "h:s", "p:s", "q:s", "help!");
##########
die $usage if ( @ARGV!=1 || defined($opts{"help"}));

###################################################
#                  START                          #
###################################################
my $optko;
foreach my $opt(keys %opts){
	$optko .= " -$opt $opts{$opt}";
}
print "##########Start############ perl $0 @ARGV ($optko)\n";
Ptime("Start");
my $infile=shift;
my $outname = $opts{o};
die "Input out name use -o\n" if $opts{o} eq "";
open(ROUT,">$outname.GO_KEGG.R") or die $!;
my $gc = $opts{i} eq ""?1:$opts{i};
my $H = $opts{h} eq ""?0:$opts{h};
$H = $H == 0?"F":"T";
my $P = $opts{p} eq ""?1:$opts{p};
my $Q = $opts{q} eq ""?1:$opts{q};
#############
my %Lake;
print ROUT"
#if (!requireNamespace(\"BiocManager\", quietly = TRUE))
#    install.packages(\"BiocManager\")
#BiocManager::install(\"DOSE\")
#BiocManager::install(\"clusterProfiler\")
#BiocManager::install(\"enrichplot\")
#BiocManager::install(\"GOplot\")

library(\"clusterProfiler\")
library(\"org.Hs.eg.db\")
library(\"enrichplot\")
library(\"ggplot2\")
library(\"DOSE\")
library(\"GOplot\")

file=read.table(file=\"$infile\",header = $H)

entreID2symbol = toTable(org.Hs.egSYMBOL)
ID=entreID2symbol[match(file[,$gc],entreID2symbol\$symbol),] # ID[,1] 则是转换后的id

#GO富集分析
eGO = enrichGO(OrgDb = org.Hs.eg.db,
		gene=ID[,1],
		ont=\"all\",
		pvalueCutoff = $P,
		qvalueCutoff = $Q,
		readable =T)
write.table(eGO,file=\"$outname.GO.txt\",sep=\"\t\",quote=F,row.names = F) #保存富集结果
#柱状图
pdf(file=\"$outname.GO.barplot.pdf\",width = 10,height = 8)
barplot(eGO, drop = TRUE, showCategory =10, split=\"ONTOLOGY\") + facet_grid(ONTOLOGY~., scale='free')
dev.off()
#气泡图
pdf(file=\"$outname.GO.bubble.pdf\",width = 10,height = 8)
dotplot(eGO, showCategory = 10, split=\"ONTOLOGY\", orderBy = \"GeneRatio\") + facet_grid(ONTOLOGY~., scale='free')
dev.off()

#kegg富集分析
eKE <- enrichKEGG(organism = \"human\",
		gene = ID[,1],
		pvalueCutoff =$P,
		qvalueCutoff =$Q)
write.table(eKE,file=\"$outname.KEGG.txt\",sep=\"\t\",quote=F,row.names = F) #保存富集结果
#柱状图
pdf(file=\"$outname.KEGG.barplot.pdf\",width = 10,height = 7)
barplot(eKE, drop = TRUE, showCategory = 30)
dev.off()
#气泡图
pdf(file=\"$outname.KEGG.bubble.pdf\",width = 10,height = 7)
dotplot(eKE, showCategory = 30,orderBy = \"GeneRatio\")
dev.off()
";
system("R CMD BATCH $outname.GO_KEGG.R");
#############

close OUT;

Ptime("End");
print "##########End############\n";

