#!/usr/bin/perl -w
use strict;

my $line="";
my $tmp="";
my $i=0; 
my @file=();
my $path="";

my $id="";
my %seq=();
my $k="";
my %leng=();
my @len=();
my $ave=0;
goto R;
&parse_command_line();

if(length($path)==0){
	&useage();
	exit(0);
}

#######################################################
open OUT,">convert.sh";
opendir(DIR,$path) or die "$!";
while($tmp=readdir DIR){
	if(-d $path.$tmp){
		opendir(FIL,"$path\/$tmp");
		while(my $bam=readdir FIL){
			if(-f "$path/$tmp/$bam" and $bam=~/^(.*)\.subreads\.bam$/){
				print OUT "bamtools convert -format fasta -in $path","$tmp\/$bam -out ",$1,".subreads.fasta\n";
			}
		}
		closedir FIL;
	}
}
closedir DIR;
$tmp=`wc -l convert.sh`;
chomp $tmp;
system("/home/leon/software/cmd_process_forker.pl -c convert.sh --CPU $tmp");
`rm convert.sh`;

######################################################
open IN,"cat *fasta|" or die "$!";
while($line=<IN>){
        chomp $line;
        if($line=~/^>(m\d+_\d+_\d+\/\d+)\/\d+_\d+$/ and length($id)==0){
                $id=$1;
        }
        elsif($line=~/^>(m\d+_\d+_\d+\/\d+)\/\d+_\d+$/ and length($id)>0){
                push(@{$seq{$id}},length($tmp));
                $tmp="";
                $id=$1;
        }
        else{
                $tmp.=$line
        }
}
push(@{$seq{$id}},length($tmp));
close IN;
open OUT,">Pacbio1.out";
foreach $k (keys %seq){
        foreach $i (@{$seq{$k}}){
                print OUT $i,"\t",scalar(@{$seq{$k}}),"\n";
        }
}
close OUT;
####################################################
foreach $k (keys %seq){
        if($#{$seq{$k}}==0){
                push(@{$leng{"1"}},${$seq{$k}}[0]);
                #print OUT $k,"\t",${$seq{$k}}[0],"\t","1\n";
        }
        elsif($#{$seq{$k}}==1){
                my @len=sort {$a<=>$b} @{$seq{$k}};
                push(@{$leng{"2"}},${$seq{$k}}[1]);
                #print OUT $k,"\t",${$seq{$k}}[1],"\t","2\n";
        }
        else{
                @len=sort {$a<=>$b} @{$seq{$k}};
                foreach $i (1..$#len){
                        $ave+=$len[$i]
                }
                $ave=$ave/$#len;
                push(@{$leng{$#len+1}},$ave);
                $ave=0;
                #print OUT $k,"\t",$ave,"\t",$#len+1,"\n";
        }
}
open OUT,">Pacbio2.out";
$tmp=0;my $C=0;
foreach $k (sort{$a<=>$b} keys %leng){
        my @ele=sort {$b<=>$a} @{$leng{$k}};
        foreach $i (@ele){
                $C+=$k;
                $tmp+=$i;
                print  OUT $C,"\t",$tmp,"\t",$k,"\n";
        }
}
close OUT;
#####################################################
R:
open OUT,">length.r";
print OUT <<EOF;
#!/usr/bin/Rscript

library(IDPmisc)
data<-read.table("Pacbio1.out",header=F)
names(data)<-c("x","y")
tiff("Pacbio1.tif",width=12,height=12,units="in", compression="lzw", res=300)
with(data, iplot(x,y,zmax=1000000,xlab="Subread Length",ylab="Subread Number"))
dev.off()
################################################
################################################
library(ggplot2)
f<-read.table("Pacbio2.out",header=F)
names(f)<-c("x","y","z")
df<-data.frame(x=f\$x,y=f\$y,z=f\$z)
df\$z<-factor(df\$z)
tiff("Pacbio2.tif",width=12,height=12,units="in", compression="lzw", res=300)
p=ggplot(data = df, mapping = aes(x = x, y = y, colour = z )) + geom_point(size = 0.01)+scale_colour_identity()+ labs(x="Accumulated Subread Number",y="Accumulated Effective Length")
p
dev.off()

EOF
close OUT;
system("chmod 755 length.r");
system("R <length.r --no-save");
#####################################################
sub parse_command_line
{
	if(scalar @ARGV==0){
		&usage();
		exit(0);
	}
	else{
		while(@ARGV){
			$tmp =shift @ARGV;
			if($tmp=~/^-p$/){ $tmp=shift(@ARGV);$path=$tmp}
			elsif($tmp=~/^-h$/){
				&usage()
			}
			else{
				print STDERR "Unknown command line: $tmp\n";
				&usage();
				exit(0);
			}
		}
	}
}

sub usage{
	print STDERR <<EOQ;

	Pacbio.statistic.pl

	version 1.0

	-p: path to the top directory that including the bam files of subread
	-h: help

EOQ
}
