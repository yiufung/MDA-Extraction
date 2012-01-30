#!/usr/local/bin/perl

# Noah Smith
# 4/17/08

# Script to extract "item 7" from a 10-K report.
# This is not perfect, but seems to work more than 80% of the time.
# Run this on a single file *after* you have extracted text (e.g., using
# lynx --force-html --dump).

# This will write the "good" part of the file to stdout, and will write
# a "schema string" on a single line to stderr.

while($line = <>) { $x .= $line; } # read the whole file into one string

# $x =~ s/^(\-|\s)*$//gs; # not in Bryan's script; probably not used in generating the data

# these are the magic regexps that break the file into parts based on the names of items 7, 7a, and 8:
$x =~ s/([^\"])(item\s+7[^0-9a-z\"]*management(?:[^0-9a-z]{0,3}s)?\s+discussions?\s+and\s+analysis\s+of\s+(?:financial\s+conditions?\s+|results\s+of\s+operations?)(?:\s+and\s+results\s+of\s+operations?|\s+and\s+financial\s+conditions?)?)/\1#######ITEM7:\2#######/gis;
$x =~ s/([^\"])(item\s+7[^0-9a-z\"]*a[^0-9a-z\"]*(?:quantitative\s+and\s+(?:qualitative|qualification)\s+disclosures?\s+about\s+)?market\s+risk)/\1#######ITEM7A:\2#######/gis;
$x =~ s/([^\"])(item\s+8[^0-9a-z\"]*.{0,40}financial\s+statements[^\.])/\1#######ITEM8:\2#######/gis;
@X = (split /\#\#\#\#\#\#\#/, $x); # tokenized raw file with some notes
for($i = 0; $i < scalar(@X); ++$i) {
  if($X[$i] =~ m/^(ITEM(?:7|7A|8)):(.*)$/s) {
    $Z[$i] = $2; # this is what will get written out, maybe
    $Y[$i] = $i . ':' . $1; # this is for the schema output (stderr)
  } else {   
    $Z[$i] = $X[$i]; # this is what will get written out, maybe
    $Y[$i] = $i . ':' . length_in_words($X[$i]);  # for schema output (stderr)
  }
}

$y = join " ", @Y; # magic schema string (with indices)
(@M) = ($y =~ m/((?:\d+:ITEM7 \d+:\d+ )+(?:\d+:ITEM7A \d+:\d+ )*)(?:\d+:ITEM8 \d+:\d+\s*)+/g); # find all matches of ITEM7 stuff ITEM7A stuff ITEM8, and remember them so we can decide which one to extract ...

# ... figure out which match is the best one, if there are any.  currently, 
# "best" equals "longest number of words excluding the headers."
$best = 0;
$bestseq = "";
for($i = 0; $i < scalar(@M); ++$i) {
  $m = $M[$i];
  $m =~ s/\d+://g;
  (@m) = (split / /, $m);
  $v = 0;
  map { $v += $_ if($_ =~ m/^\d+$/); } @m;
  if($v > $best) { $best = $v; $bestseq = $M[$i]; }
}

# if we have a best match, write it out!
if($bestseq ne "") {
  $bestseq =~ s/:\S+//g;
  (@m) = (split / /, $bestseq);
  map { $Z[$_] =~ s/\s*$/\n/; print $Z[$_]; $kept{$_} = 1; } @m;
}
else { print STDERR "(NO_MATCH) "; }

# write out the schema of the file to stderr so we can think more
# deeply about our regexps and debug ... put stars next to the bits we extract
$y =~ s/\b\d+://g; # (strip human-unreadable indices out of magic schema string)
@Y = split / /, $y;
for($i = 0; $i < scalar(@Y); ++$i) {
  print STDERR "*" if(defined $kept{$i});
  print STDERR $Y[$i], " ";
}
print STDERR "\n";

sub length_in_words {
  my $x = shift;
  my @k;
  return scalar(@k = $x =~ m/(\S+)/sg);
}
