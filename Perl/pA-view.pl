#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This is a line-based utility for extracting pA sites from SAM files\n";
}

parse_command_line( read1 => {description=>'flip read1 yes/no (1/0)', default=>1},
		    read2 => {description=>'flip read2 yes/no (1/0)', default=>0},
		    readLength => {description=>'read length', ifabsent=>'not specified'},
		    minmatch => {description=>'min number of nucleoties for match part', default=>31},
		    mintail  => {description=>'min number of nucleoties for polyA part', default=>4},
		    minpercenta => {description=>'min percent A in polyA tail', default=>80},
		    bam   => {description=>'input bam file', ifabsent=>'not specified'},
		    lim   => {description=>'stop after this number of lines (for debug)',default=>0});
 
$BAM_FREAD1 = 0x40;
$BAM_FREAD2 = 0x80;
$BAM_FREVERSE = 0x10;
@STRAND = ("+", "-");

@read = ($read1, $read2);
for($s=0; $s<2; $s++) {
    print STDERR "[Warning: will take reverse complement of read ", $s+1, "]\n" if($read[$s] % 2);
}

open FILE, "sjcount-3.1/samtools-0.1.18/samtools view $bam |" || die();
while(<FILE>){
    ($id, $flag, $ref, $pos, $qual, $cigar, $z, $z, $z, $seq) = split /\t/;
    $s = (($flag & $BAM_FREVERSE)>0);
    $strand = ($flag & $BAM_FREAD1) ? ($s + $read[0]) & 1 : ($s + $read[1]) & 1;

    $n++;
    last if($n>$lim && $lim>0);

    @array = ();
    if($strand == 0 && $cigar=~/(\d+)M(\d+)S/) {
	$x = $1;
	$y = $2;
	next unless($x >= $minmatch && $y >= $mintail);
	$t = substr($seq,-$y,$y);
	$t =~ s/A//g;
	$p = int(100*(1-length($t)/$y));
	next unless($p >= $minpercenta);
	substr($seq,-$y,$y) =~ tr/[A-Z]/[a-z]/;
	print $seq,"\n";
    }
    if($strand == 1 && $cigar=~/(\d+)S(\d+)M/) {
	$x = $2;
	$y = $1;
	next unless($x >= $minmatch && $y >= $mintail);
        $t = substr($seq,0,$y);
        $t =~ s/T//g;
        $p = int(100*(1-length($t)/$y));
        next unless($p >= $minpercenta);
	substr($seq,0,$y) =~ tr/[A-Z]/[a-z]/;
	print rc($seq),"*\n";
    }   
}
close FILE;


foreach $key(sort keys(%count)) {
    print "$key\t$count{$key}\n";
}


sub rc {
    my $x = join("", reverse split //, @_[0]);
    $x=~ tr/ACGTacgt/TGCAtgca/;
    return($x);
} 
