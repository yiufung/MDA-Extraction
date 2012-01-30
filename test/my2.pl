#!/usr/bin/local/perl

package HTMLStrip;
use base "HTML::Parser";
use HTML::Entities;

$filename=$ARGV[0];
print "opening $filename.\n";

$content = "";

#All regular expressions use 2 modifiers, i, x, s, and g
#i for case insensitivity, so "ITEM" is the same as "item".
#x for adding whitespace inside regular expresssions, so we can add comments to improve readability.
#s for treating the expression as string. so . match literally anything, even \n
#g for global matching.
sub Item7{
  $content =~ s/
    item\s+?7  #item and arbitrary number of spaces.
    .*        #anything in between
    management.s\s+?discussion\s+?and\s+?analysis\s+?of\s+?financial\s+?condition\s+?and\s+?results\s+?of\s+?operations
    /
    ######ITEM 7######
    /gixs;
}

sub Item7a{
  $content =~ s/
    item\s+?7a
    .*
    quantitative\s+?and\s+?(qualitative|qualification)\s+?disclosures\s+?about\s+?market\s+?risk
    /
    ######ITEM 7a######
    /gixs;
}

sub Item89{
  #return true if it's item 8.
  $content =~ s/
    item\s+?8
    .*
    financial\s+?statements
    /
    ######ITEM 8######
    /gixs;
  #while there isn't item 8.
  $content =~ s/
    item\s+?9a?
    .*
    changes\s+?in\s+?and\s+?
    /
    ######ITEM 9######
    /gixs;
}

###########
## Start ##
###########

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
$plainTextInOneLine = HTML::Entities::decode($contentInOneLine);
#start from the 5% so skip the table of contents part.
$startPos = length($plainTextInOneLine) * 0.05;

$content = substr($plainTextInOneLine, $startPos);

#subsitution.
Item7($content);
Item7a($content);
Item89($content);

#split lines into array.
@all = split /\#\#\#\#\#\#/, $content;
#prepare 2 empty strings for output.
$output7="";
$output7a="";
$exist7=0;
$exist7a=0;

#now it's in such a pattern.
# sth######ITEM7######Content of Item 7######ITEM7a######Content of Item7a
for($i = 0; $i < scalar(@all); ++$i){
  if($i =~ m/^ITEM (7|7a|8|9)$/s){
    #then $all[$i+1] should store the string I want.
    if($i =~ m/^ITEM 7$/s){
      $exist7=1;
      $output7=$all[++$i];
    }
    elsif($i =~ m/^ITEM 7a$/s){
      $exist7a=1;
      $output7a=$all[++$i];
    }
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
