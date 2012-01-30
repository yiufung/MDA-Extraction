#!/usr/bin/local/perl

package HTMLStrip;
use base "HTML::Parser";
use HTML::Entities;

$filename=$ARGV[0];
print "opening $filename.\n";

#All regular expressions use 2 modifiers, i and x.
#i for case insensitivity, so "ITEM" is the same as "item".
#x for adding whitespace inside regular expresssions, so we can add comments to improve readability.
sub Item7TitleMatcher{
  my $string = $_[0];
  if($string =~ m/
    item\s+?7  #item and arbitrary number of spaces.
    .*        #anything in between
    management.s\s+?discussion\s+?and\s+?analysis\s+?of\s+?financial\s+?condition\s+?and\s+?results\s+?of\s+?operations
    /ix){
    return 1;
  }
  else{
    return 0;
  }
}

sub Item7aTitleMatcher{
  my $string = $_[0];
  if($string =~ m/
    item\s+?7a
    .*
    quantitative\s+?and\s+?(qualitative|qualification)\s+?disclosures\s+?about\s+?market\s+?risk
    /ix){
    return 1;
  }
  else{
    return 0;
  }
}

sub Item89TitleMatcher{
  my $string = $_[0];
  #return true if it's item 8.
  if($string =~ m/
    item\s+?8
    .*
    financial\s+?statements
    /ix){
    return 1;
  }
  #return true while there isn't item 8.
  elsif($string =~ m/
    item\s+?9a?
    .*
    changes\s+?in\s+?and\s+?
    /ix){
    return 1;
  }
  else{
    return 0;
  }
}

#global string to store all the content;
$contentInOneLine="";
#override the method in HTML::Parser to add the target text into $string.
sub text{
  my ($self, $text) = @_;
  $contentInOneLine.=$text;
}

my $p = new HTMLStrip;
#use <> so we can read from command line.
while(<>){
  $p->parse($_);
}
$p->eof;#flush the parser.


#By so far we get the whole text in one line.
#Before extracting, substitute all HTML entity code into ASCII character.
#Visit http://www.w3schools.com/tags/ref_ascii.asp for the whole table.
#Here we use the HTML::Entities module.
$plainTextInOneLine= HTML::Entities::decode($contentInOneLine);

#split lines into array.
@all = split /\n/, $plainTextInOneLine;
$lineNumber = scalar(@all);

#start from the 5% so skip the table of contents part.
$start = $lineNumber * 0.05 ;

#prepare 2 empty strings for output.
$output7="";
$output7a="";
$exist7=0;
$exist7a=0;

for($i=$start; $i<$lineNumber; ++$i){ # $i to loop the whole array.
  if(Item7TitleMatcher($all[$i])){
    $exist7=1;
    print "Start extracting Item 7\n";
    while(!Item7aTitleMatcher($all[$i]) and !Item89TitleMatcher($all[$i])){
      $output7.="$all[$i]\n";
      ++$i;
    }
    print "End extracting Item 7\n";
  }
  if(Item7aTitleMatcher($all[$i])){
    $exist7a=1;
    print "Start extracting Item 7A\n";
    while(!Item89TitleMatcher($all[$i])){
      $output7a.="$all[$i]\n";
      ++$i;
    }
    print "End extracting Item 7A\n";
  }
}

#Output to 2 individual files.
$item7file=$filename."_7";
$item7afile=$filename."_7a";
$fileout=$filename."_out";
open (FILEOUT, "> $fileout");
print FILEOUT $plainTextInOneLine;
close FILEOUT;
if($exist7){
  print "Generating Item 7 file\n";
  open (ITEM7, "> $item7file");
  print ITEM7 $output7;
  close ITEM7;
  print "Item 7 output to file: $item7file\n";
}
if($exist7a){
  print "Generating Item 7a file\n";
  open (ITEM7A, "> $item7afile");
  print ITEM7A $output7a;
  close ITEM7A;
  print "Item 7a output to file: $item7afile\n";
}
