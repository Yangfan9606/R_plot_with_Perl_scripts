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

Program : multiple files plot stackbar plot, one file correspend to one Bar

Usage: .pl [in1,in2,in3...] -o [out.name]
        -i                      input column [2]
        -head                   header or not (0/1) [1]
        -xlab                   xlab []
        -ylab                   ylab [Y]
        -xlim                   xlim (0,1) [min,max]
        -ylim                   ylim (0,1) [min,max]
        -xbreak                 xbreaks (0,1,0.1) [min,max,2] 可用 min,max
        -ybreak                 ybreaks (0,1,0.1) [min,max,2] 可用 min,max
        -name                   name of each file [file_name]
        -W                      width [8]
        -H                      height [8]
        -o                      out name
        -help                   output help information

USAGE

GetOptions(\%opts, "l:s", "b:s", "o:s", "u:s", "i:s", "x:s","y:s","h:s","head:s","xlab:s","ylab:s","xlim:s","ylim:s","xbreak:s","ybreak:s","name:s","xlog:s","ylog:s","W:s", "H:s",          "help!");
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
my @infile=split/,/,shift;
my $outname = $opts{o};
die "Input out name use -o\n" if $opts{o} eq "";
my $Rfile = "$outname.R";
open(OUT, ">$Rfile") or die $!;

##############################################
my $head = $opts{h}==1?"header=T":"header=F";
my $input_col = $opts{y} eq ""?2:$opts{i};
my $xlab = $opts{xlab} eq ""?"":$opts{xlab};
my $ylab = $opts{ylab} eq ""?"Y":$opts{ylab};
my @XL = split/,/,$opts{xlim};
my $xlim = $opts{xlim} eq ""?"":",limits=c($XL[0],$XL[1])";
my @YL = split/,/,$opts{ylim};
my $ylim = $opts{ylim} eq ""?"":",limits=c($YL[0],$YL[1])";
my @XB = split/,/,$opts{xbreak};
my $xb = $opts{xbreak} eq ""?"":",breaks=seq($XB[0],$XB[1],by=$XB[2])";
$opts{ybreak} =~ s/^,// if $opts{ybreak} ne "";
my @YB = split/,/,$opts{ybreak};
my $yb = $opts{ybreak} eq ""?"":",breaks=seq($YB[0],$YB[1],by=$YB[2])";
my $Xlog = $opts{xlog};
my $Ylog = $opts{ylog};
my $W = $opts{W} eq ""?8:$opts{W};
my $H = $opts{H} eq ""?8:$opts{H};
my @Name = @infile;
if (defined($opts{"name"})){
        @Name = split/,/,$opts{name};
#       print "name = @N\n";
}
#############
my $CN = @infile;
print OUT "
library(ggplot2)
library(ggpubr)
library(stringr)
library(RColorBrewer)
library(patchwork)
library(plyr)
library(tidyr)
library(dplyr)
library(reshape2)

qual_col_pals = brewer.pal.info[brewer.pal.info\$category == 'qual',]
col_vector = unlist(mapply(brewer.pal, qual_col_pals\$maxcolors,rownames(qual_col_pals)))
###############################
pdf(\"$outname.StackBar.pdf\",w=$W,h=$H)
";
my $n=1;
for (my $i=0;$i<@infile;$i++){
my $f = $infile[$i];
my $dn = "data$n"."[,c(1,$input_col)]";
print OUT "data$n=read.table(file=\"$f\",$head)
d$n=$dn
colnames(d$n)=c('Group','$Name[$i]')
";
$n++;
}
print OUT "df=join(d1,d2,type = 'full')\n";
for (my $i=3;$i<=@infile;$i++){
print OUT "df=join(df,d$i,type = 'full')
";
}
##########
print OUT "
tdf=as.data.frame(t(df))
colnames(tdf)=tdf[1,]
tdf=tdf[-1,]
id=rownames(tdf)
rd=cbind(x=id,tdf)
data_long<-melt(df,id.vars='Group')
### options(scipen=200) # no Scientific notation
n=20+ncol(tdf)
col=col_vector[20:n]

ggplot(data=data_long,aes(variable,value,fill=Group))+
  geom_bar(stat='identity',position='stack', color='black', width=0.75,size=0.25)+
  scale_fill_manual(values=c(col))+
  labs(x = '$xlab',y= '$ylab')+
  theme_classic()+
  theme(axis.text=element_text(size=14),
        axis.title = element_text(size=16),
        legend.text = element_text(size=14)
        )+
###  scale_y_continuous(expand = c(0,0),labels=fancy_scientific)+
  scale_y_continuous(expand = c(0,0),$ylim,$yb)

";
#############
print OUT "
dev.off()
############################
fancy_scientific <- function(l) {
  # turn in to character string in scientific notation
  l <- format(l, scientific = TRUE)
  l <- gsub(\"0e\\\\+00\",\"0\",l)
  # quote the part before the exponent to keep all the digits
  l <- gsub(\"^(.*)e\", \"'\\\\1'e\", l)
  # remove \"+\" after exponent, if exists. E.g.: (3x10^+2 -> 3x10^2)
  l <- gsub(\"e\\\\+\",\"e\",l)
  # turn the 'e+' into plotmath format
  l <- gsub(\"e\", \"%*%10^\", l)
  # convert 1x10^ or 1.000x10^ -> 10^
  l <- gsub(\"\\\\'1[\\\\.0]*\\\\'\\\\%\\\\*\\\\%\", \"\", l)
  # return this as an expression
  parse(text=l)
}
";
close OUT;

Ptime("End");
print "##########End############\n";
system("R CMD BATCH $Rfile");
