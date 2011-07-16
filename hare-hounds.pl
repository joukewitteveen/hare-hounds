#!/usr/bin/perl
use strict;
use File::Temp 'tempfile';

my $gnuplot = <<'END';
set timefmt '%Y-%m-%d'
set datafile missing '-'
set xdata time
set format x '%d %b'
set logscale y
set yrange [24:44]
set ytics (25,26,27,28,29,30,31 1,32,33 1,34,35 1,36,37 1,38,39 1,40,41 1,42,43 1)
set grid ytics
set ylabel 'minuten'
set key horiz center top
END

my $output = ($ARGV[$#ARGV] or $0);
$_ = rindex $output, '.';
$_ = length $output if $_ < $[ or $_ + 4 < length $output;
substr $output, $_, 4, '.png';
$gnuplot .= <<"END";
set term pngcairo size 1024,640
set output '$output'
END

my @individuals = split ' ', <> or die 'no header found';

(my $tmph, my $tmp_name) = tempfile( UNLINK => 1 ) or die 'could not open temporary file';

$gnuplot .= 'set xtics (';
while( <> ){
  s/(\d+):(\d+)/$1+$2\/60/eg;
  print $tmph $_;
  /^(?!#)\S+/ and $gnuplot .= "'$&',";
}
substr $gnuplot, -1, 2, ")\n";

$gnuplot .= 'plot ';
foreach( 1 .. $#individuals ) {
  $gnuplot .= "'$tmp_name' using 1:" . ($_ + 1) . " with linespoints title '$individuals[$_]'," unless $individuals[$_] =~ /^#/;
}
substr $gnuplot, -1, 1, "\n";

$gnuplot =~ s/\\\n//g;
$gnuplot =~ s/\n/;/g;
system( "gnuplot -e \"$gnuplot\"\n" ) == 0 or die 'could not execute gnuplot';
