### Wirted by Yangfan Zhou at Westlake University, zhouyangfan@westlake.edu.cn
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

Program : input Two files to plot R cor point plot (第一列为统一ID)

Usage: .pl [in1,in2] -o [out.name]
        -x                      x column value of file 1 [2]
        -y                      y column value of file 2 [2]
        -log                    log [none] (2/10)
        -head                   header or not (0/1) [1]
        -xlab                   xlab [X]
        -ylab                   ylab [Y]
        -xbreak                 xbreaks (0,1,0.1) [min,max,2] 可用 min,max
        -ybreak                 ybreaks (0,1,0.1) [min,max,2] 可用 min,max
        -W                      width [4]
        -H                      height [4]
        -o                      out name
        -help                   output help information

USAGE

GetOptions(\%opts, "l:s", "b:s", "o:s", "u:s", "i:s", "x:s","y:s","h:s","head:s","xlab:s","ylab:s","xlim:s","ylim:s","xbreak:s","ybreak:s","name:s","xlog:s","ylog:s","W:s", "H:s", "log:s", "help!");
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
my $X = $opts{x} eq ""?2:$opts{x};
my $Y = $opts{y} eq ""?2:$opts{y};
my $xlab = $opts{xlab} eq ""?"X":$opts{xlab};
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
my $log = $opts{log};
if ($log ne ""){
        $log = "log$log";
}
my $W = $opts{W} eq ""?4:$opts{W};
my $H = $opts{H} eq ""?4:$opts{H};
my @Name = @infile;
if (defined($opts{"name"})){
        @Name = split/,/,$opts{name};
#       print "name = @N\n";
}
#############
my $CN = @infile;
print OUT "
library(ggpubr)
library(stringr)
library(plyr)
###############################
data1=read.table('$infile[0]',$head,sep='\\t')
data2=read.table('$infile[1]',$head,sep='\\t')
d1=data1[,c(1,$X)]
d2=data2[,c(1,$Y)]
d1[,2]=$log(d1[,2])
d2[,2]=$log(d2[,2])
colnames(d1)=c('ID','$xlab')
colnames(d2)=c('ID','$ylab')
df=join(d1,d2,type='full')
pdf(\"$outname.pdf\",w=$W,h=$H)
ggscatter(df, x = '$xlab', y = '$ylab',
          color = 'black', size = 2, # Points color, shape and size
          # shape = 21,
          add = 'reg.line',  # Add regressin line
          add.params = list(color = 'blue', fill = 'lightgray'), # Customize reg. line
          conf.int = TRUE, # Add confidence interval
          cor.coef = TRUE, # Add correlation coefficient. see ?stat_cor
          cor.coeff.args = list(method = 'pearson', label.x = 3, label.sep = '\n')
)
";
#############
print OUT "
dev.off()
";
close OUT;

Ptime("End");
print "##########End############\n";
system("R CMD BATCH $Rfile");
