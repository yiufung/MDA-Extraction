#!/usr/bin/local/perl

# Reminder:
#   Item 6. Management / latter part
#   Go all the way to extract. Logic in until
# Overwrite..= =

# Perl script for extracting MD&A from 10-k forms.
# by Cheong Yiufung @ HKUST 
# instructed by Prof. Allen Huang and with help from Xia Jingjing.
# 09/02/12 

# Usage:
# perl extract.pl <filename>
# The script will then generate <filename>_mda and <filename>_quant if the corresponding item is extracted.
# Whether it successfully extracts or not, it will generate <filename>_plaintext, which contains the plain text after decoding from HTML.
# You can feed <filename>_out to extract_MDA.pl to check the difference.
# Use rm *_7 *_7a *_out to remove generated files.

######## Declaration of packages used #########
package HTMLStrip;
use base "HTML::Parser";
use HTML::Entities;
use utf8;

######## Declaration and Definition of functions #######

# All regular expressions use 4 modifiers, i, x, s, and g
# i for case insensitivity, so "ITEM" is the same as "item".
# x for adding whitespace inside regular expresssions, so we can add comments to improve readability.
# s for treating the expression as string. so . match literally anything, even \n
# g for global matching.
# Note: ? added after + or * (such as .*? \s+?) are for non-greedy pattern matching.
sub MDA{
  # $change to record how many substitution has taken place. 
  $change = $content =~ s/
    (?<!\")(?<!\,\ )(?<!in\ )(?<!and\ )(?<!or\ )(?<!not\ )(?<!see\ )(?<!to\ )(?<!with\ )(?<!under\ )(?<!regarding\ )(?<!by\ )(?<!the\ )(?<!caption\ )(?<!read\ )(?<!at\ )(?<!following\ )(?<!both\ )(?<!also\ )(?<!of\ )(?<!within\ )
        ###IMPORTANT COMMENT###
            # This part declare words and symbols that CANNOT appear BEFORE the item. 
            # include : " , in and see to with under regarding by the caption read at following both 
            # This means the item is not being quoted nor referenced, hence escape from all the quoting rules and refernce sentences. 
            # Explanations on rules:
              # after ", there is no space, so use (?<!\")
              # after word, there should be one space, so use (?<!word\ )
          # Add new rules according to above patterns. Possibly syntax could be simpler but I haven't found the way, so you have to do this tedious work, sorry.
          # IMPORTANT REMINDER: also update the words in subroutine Quantitative and setStopSign. You should update 4 regex in total (2 in setStopSign). 
        ###Continue of Regex###
    item\s+?7
      # item and arbitrary number of spaces.
    [^Aa]*?
      # anything in between except A, so won't match 7A.
    .{0,25}
      #anything in between for at most 25 characters. it match item 6, 7 and other situations. 
      #also cause problems of overrunning. 
    management.?s?\s+?discussions?\s+?and\s+?analysis\s+?
        # the necessary part
      (of\s+?financial\s+?conditions?|of\s+?results\s+?of\s+?operations?|or\s+?plans?\s+?of\s+operations?)?
          # "financial conditions" and "results of operations" may come in different order.
      (\s+?and\s+?results\s+?of\s+?operations?|\s+?and\s+?financial\s+?conditions?)?
          # the latter part may be unnecessary, so ? mark is used in the last.
    /
    ######SPLIT MDA######
    /gixs;

  ## Detect Item 7 Financial statements.
  if($content =~ m/
    item\s+?7
    [^Aa]*?
    (Consolidated)?\s+?financial\s+?statements?
    /gixs){
    print "Invalid Item 7: Financial statements found. \n";
  }

  if($change == 0){
    ## Big chance that MDA is hidden in Item 6. 
    print "Try to find MDA in Item 6. \n";
    TryMDA6();
  }
}

# The function try to assert whether MDA is in Item 6. 
# It only gets called when MDA is NOT in Item 7. 
# May assert the global variable $MDAinItem6
sub TryMDA6{
  ## Similar regex to the Item 7 one. 
  $change = $content =~ s/
      (?<!\")(?<!\,\ )(?<!in\ )(?<!and\ )(?<!or\ )(?<!not\ )(?<!see\ )(?<!to\ )(?<!with\ )(?<!under\ )(?<!regarding\ )(?<!by\ )(?<!the\ )(?<!caption\ )(?<!read\ )(?<!at\ )(?<!following\ )(?<!both\ )(?<!also\ )(?<!of\ )(?<!within\ )
  item\s+?6
  [^Aa]*?
  .{0,25}
  management.?s?\s+?discussions?\s+?and\s+?analysis\s+?
    (of\s+?financial\s+?conditions?|of\s+?results\s+?of\s+?operations?|or\s+?plans?\s+?of\s+operations?)?
    (\s+?and\s+?results\s+?of\s+?operations?|\s+?and\s+?financial\s+?conditions?)?
  /
  ######SPLIT MDA######
  /gixs;

  if ($change != 0){ # MDA is in Item 6. 
    $MDAinItem6=1;
  }
}

sub Quantitative{
  $content =~ s/
    (?<!\")(?<!\,\ )(?<!in\ )(?<!and\ )(?<!or\ )(?<!not\ )(?<!see\ )(?<!to\ )(?<!with\ )(?<!under\ )(?<!regarding\ )(?<!by\ )(?<!the\ )(?<!caption\ )(?<!read\ )(?<!at\ )(?<!following\ )(?<!both\ )(?<!also\ )(?<!of\ )(?<!within\ )
    item\s+?7\.?\s*a # Sometimes may be 7.A
    .*?
    (quantitative|qualitative)\s+?and\s+?(quantitative|qualitative|qualification)\s+?disclosures?\s+?about\s+?market\s+?risk
    /
    ######SPLIT QUANT######
    /gixs;
}

sub setStopSign{
  $content =~ s/
    (?<!\")(?<!\,\ )(?<!in\ )(?<!and\ )(?<!or\ )(?<!not\ )(?<!see\ )(?<!to\ )(?<!with\ )(?<!under\ )(?<!regarding\ )(?<!by\ )(?<!the\ )(?<!caption\ )(?<!read\ )(?<!at\ )(?<!following\ )(?<!both\ )(?<!also\ )(?<!of\ )(?<!within\ )
    item\s+?8
    .*?
    financial\s+?statements
    /
    ######SPLIT STOPSIGN######
    /gixs;

  $content =~ s/
    (?<!\")(?<!\,\ )(?<!in\ )(?<!and\ )(?<!or\ )(?<!not\ )(?<!see\ )(?<!to\ )(?<!with\ )(?<!under\ )(?<!regarding\ )(?<!by\ )(?<!the\ )(?<!caption\ )(?<!read\ )(?<!at\ )(?<!following\ )(?<!both\ )(?<!also\ )(?<!of\ )(?<!within\ )
    item\s+?9a?
    .*
    changes\s+?in\s+?and\s+?
    /
    ######SPLIT STOPSIGN######
    /gixs;
  
  # SPECIAL:
  # When MDAinItem6 = 1, probably Item 7 Financial Statements is a stop sign. 
  # Set here. 
  if($MDAinItem6){
    $content =~ s/
      item\s+?7
      [^Aa]*?
      (Consolidated)?\s+?financial\s+?statements?
      /
      ######SPLIT STOPSIGN######
      /gixs;
  }
}

#Debug mode. 
$debug=1;

# Item 6 as MDA mode. asserted in MDA().
# In such situation, it's probable that Item 7 is financial statements.
# need to reset the stop sign under such situation
# Function influenced include: setStopSign() (set Item 7 financial statements as stop sign. )
$MDAinItem6=0;

if($debug == 1){ print "before extract.\n";}

# global string to store all the content;
$contentInOneLine="";
# override the method in HTML::Parser to add the target text into $string.
sub text{
  my ($self, $text) = @_;
  $contentInOneLine.=$text;
}

############# Start of Process #############

# Read file in.
$filename=$ARGV[0];
open (FILE, "< $filename") 
  or die "$filename cannot be open: $!\n";

my $p = new HTMLStrip;
while(<FILE>){
  # function called procedures:
  # parse($_) ->  text($_) -> added into $contentInOneLine.
  $p->parse($_);
}
$p->eof;# flush the parser.
close FILE;

if($debug==1){ print "file read.\n";}

# By so far we get the whole text in one line.
# Before extracting, substitute all HTML entity code into ASCII character.
$plainTextInOneLine = HTML::Entities::decode($contentInOneLine);

# Substitute all the UTF-8 encoded character into us-ascii character.
# Not a full list, but should be enough to eliminate all the strange characters and help proceed
#   the substitution in the regex.
$plainTextInOneLine =~ s//'/gs;
$plainTextInOneLine =~ s//"/gs;
$plainTextInOneLine =~ s//"/gs;
$plainTextInOneLine =~ s//./gs;
$plainTextInOneLine =~ s//-/gs;
$plainTextInOneLine =~ s//-/gs;
$plainTextInOneLine =~ s/’/'/gs;
$plainTextInOneLine =~ s/\xc2\xa0/ /gs;
$plainTextInOneLine =~ s/\xa0/ /gs;
# Get rid of non-ASCII characters to avoid Warnings like "Wide character in print". 
# Hopefully dumping several characters(normally they're space or some strange characters) won't hurt the text. Comment it if you wish. 
$plainTextInOneLine =~ s/[^[:ascii:]]+//g;  

# start from the 5% to skip the table of contents part.
$startPos = length($plainTextInOneLine) * 0.05;

$content = substr($plainTextInOneLine, $startPos);

if($debug==1){ print "before matching. \n";}

# Matching and substitution.
if($debug==1){ print "MDA starts matching. \n";}
MDA();
if($debug==1){ print "MDA fin matching. \n";}

if($debug==1){ print "QUANT starts matching. \n";}
Quantitative();
if($debug==1){ print "QUANT fin matching. \n";}

if($debug==1){ print "STOPSIGN starts matching. \n";}
setStopSign();
if($debug==1){ print "STOPSIGN fin matching. \n";}


# split lines into array.
@all = split /\#\#\#\#\#\#/, $content;
# prepare empty strings for output.
$outputMDA="";
$outputQuant="";
$existMDA=0;
$existQuant=0;

if($debug==1){ print "before extracting.\n";}

# now it's in such a pattern.
#  sth######MDA######Content of MDA######QUANT######Content of QUANT
for($i = 0; $i < scalar(@all); ++$i){
  if($all[$i] =~ m/^SPLIT (MDA|QUANT|STOPSIGN)$/s){

    if($debug==1){ print "inside extraction.\n";}

    # now $all[$i+1] should store the string I want.
    if($all[$i] =~ m/^SPLIT MDA$/s){

      if($debug==1){ print "inside MDA.\n";}

      $existMDA=1;
      # a do-until block is used here to add consecutive segments together.
      # In some cases, there might be multiple MDA(Continue) in the file which will mess up the file. The loop will add them all together.
      do{
        if($debug==1){ print "adding MDA.\n";}
        $outputMDA.=$all[++$i];
      } until($all[$i+1] =~ m/^SPLIT QUANT$/s
            or $all[$i+1] =~ m/^SPLIT STOPSIGN$/s
            or $i==scalar(@all));
    }
    elsif($all[$i] =~ m/^SPLIT QUANT$/s){
      
      if($debug==1){ print "inside QUANT.\n";}

      $existQuant=1;
      do{
        $outputQuant.=$all[++$i];
      } until($all[$i+1] =~ m/^SPLIT STOPSIGN$/s
            or $i==scalar(@all));
    }
  }
}

if($debug==1){ print "after extracting.\n";}

# Output to 3 individual files.
$fileout=$filename."_plaintext";
$mdaFile=$filename."_mda";
$quantFile=$filename."_quant";

# out
open (FILEOUT, "> $fileout");
print FILEOUT $plainTextInOneLine;
close FILEOUT;

# 7
if($existMDA){
  open (MDAFILE, "> $mdaFile");
  print MDAFILE "MANAGEMENT'S DISCUSSION AND ANALYSIS OF FINANCIAL CONDITION AND RESULTS OF OPERATIONS\n\n";
  print MDAFILE $outputMDA;
  close MDAFILE;
  print "$mdaFile outputted.\n";
}
else{
  print "MDA in $filename not found!\n";
}

# 7a
if($existQuant){
  open (QUANTFILE, "> $quantFile");
  print QUANTFILE "QUANTITATIVE AND QUALITATIVE DISCLOSURES ABOUT MARKET RISK\n\n";
  print QUANTFILE $outputQuant;
  close QUANTFILE;
  print "$quantFile outputted.\n";
}
else{
  print "Quantitative in $filename not found.\n";
}

