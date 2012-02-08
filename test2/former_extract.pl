#!/usr/bin/local/perl
use utf8;

# Usage:
# perl extract.pl <filename>
# The script will then generate <filename>_7 and <filename>_7a if the corresponding item is extracted.
# Whether it successfully extracts or not, it will generate <filename>_out, which contains the plain text after decoding from HTML.
# You can feed <filename>_out to extract_MDA.pl to check the difference.
# You can use rm *_7 *_7a *_out to remove generated files.

package HTMLStrip;
use base "HTML::Parser";
use HTML::Entities;

$filename=$ARGV[0];
open (FILE, "< $filename") 
  or die "$filename cannot be open: $!\n";
print "reading from $filename.\n";

$content = "";

# All regular expressions use 2 modifiers, i, x, s, and g
# i for case insensitivity, so "ITEM" is the same as "item".
# x for adding whitespace inside regular expresssions, so we can add comments to improve readability.
# s for treating the expression as string. so . match literally anything, even \n
# g for global matching.
# Note: ? added after + or * (such as .*? \s+?) are for non-greedy pattern matching.
sub Item7{
  $content =~ s/
    (?<!\")(?<!in\ )(?<!and\ )(?<!see\ )(?<!to\ )(?<!with\ )(?<!under\ )(?<!regarding\ )(?<!by\ )(?<!the\ )(?<!caption\ )(?<!read\ )(?<!at\ )(?<!following\ )(?<!both\ ) 
        ###IMPORTANT COMMENT###
            # This part declare words and symbols that CANNOT appera BEFORE the item. 
            # include : " in and see to with under regarding by the caption read at following both 
            # This means the item is not being quoted nor referenced, hence escape from all the quoting rules and refernce sentences.
            # Explanations on rules:
              # after ", there is no space, so use (?<!\")
              # after word, there should be one space, so use (?<!word\ )
          # Add new rules according to above patterns. Possibly syntax could be simpler but I haven't found the way, so you have to do this tedious work, sorry.
          # IMPORTANT REMINDER: also update the words in subroutine Item7a and Item89. You should update 4 regex in total (2 in Item89). 
        ###Continue of Regex###
    item\s+?7  
        # item and arbitrary number of spaces.
    [^Aa]*?    
        # anything in between except A, so won't match 7A.
    management.?s?\s+?discussions?\s+?and\s+?analysis\s+?of\s+?
        # the necessary part
      (financial\s+?conditions?|results\s+?of\s+?operations?)
          # "financial conditions" and "results of operations" may come in different order.
      (\s+?and\s+?results\s+?of\s+?operations?|\s+?and\s+?financial\s+?conditions?)?       
          # the latter part may not be necessary, so ? mark is used here.
    /
    ######ITEM 7######
    /gixs;
}

sub Item7a{
  $content =~ s/
    (?<!\")(?<!in\ )(?<!and\ )(?<!see\ )(?<!to\ )(?<!with\ )(?<!under\ )(?<!regarding\ )(?<!by\ )(?<!the\ )(?<!caption\ )(?<!read\ )(?<!at\ )(?<!following\ )(?<!both\ ) 
    item\s+?7a
    .*?
    quantitative\s+?and\s+?(qualitative|qualification)\s+?disclosures?\s+?about\s+?market\s+?risk
    /
    ######ITEM 7a######
    /gixs;
}

sub Item89{
  $content =~ s/
    (?<!\")(?<!in\ )(?<!and\ )(?<!see\ )(?<!to\ )(?<!with\ )(?<!under\ )(?<!regarding\ )(?<!by\ )(?<!the\ )(?<!caption\ )(?<!read\ )(?<!at\ )(?<!following\ )(?<!both\ ) 
    item\s+?8
    .*?
    financial\s+?statements
    /
    ######ITEM 8######
    /gixs;
  $content =~ s/
    (?<!\")(?<!in\ )(?<!and\ )(?<!see\ )(?<!to\ )(?<!with\ )(?<!under\ )(?<!regarding\ )(?<!by\ )(?<!the\ )(?<!caption\ )(?<!read\ )(?<!at\ )(?<!following\ )(?<!both\ ) 
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

# global string to store all the content;
$contentInOneLine="";

# override the method in HTML::Parser to add the target text into $string.
sub text{
  my ($self, $text) = @_;
  $text=to_utf8($text);
  $contentInOneLine.=$text;
}

#function to change characters into utf8.
sub to_utf8 {
    local($p_str) = @_;
    if (utf8::is_utf8($p_str)){
        utf8::decode($p_str);
    }
    return($p_str);
}

my $p = new HTMLStrip;
while(<FILE>){
  $p->parse($_);
}
$p->eof;# flush the parser.

# By so far we get the whole text in one line.
# Before extracting, substitute all HTML entity code into ASCII character.
# Visit http://www.w3schools.com/tags/ref_ascii.asp for the whole table.
# Here we use the HTML::Entities module.
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
$plainTextInOneLine =~ s/[^[:ascii:]]+//g;  # Get rid of non-ASCII characters. This line is to avoid Warning like "Wide character in print". Hopefully dumping several characters(normally they're space or some strange characters) won't hurt the text. 

# start from the 5% so skip the table of contents part.
$startPos = length($plainTextInOneLine) * 0.05;

$content = substr($plainTextInOneLine, $startPos);

# Matching.
Item7();
Item7a();
Item89();

# split lines into array.
@all = split /\#\#\#\#\#\#/, $content;
# prepare 2 empty strings for output.
$output7="";
$output7a="";
$exist7=0;
$exist7a=0;

# now it's in such a pattern.
#  sth######ITEM7######Content of Item 7######ITEM7a######Content of Item7a
for($i = 0; $i < scalar(@all); ++$i){
  if($all[$i] =~ m/^ITEM (7|7a|8|9)$/s){
    # now $all[$i+1] should store the string I want.
    if($all[$i] =~ m/^ITEM 7$/s){
      $exist7=1;
      # a do-until block is used here to add consecutive segments together.
      # In some cases, there might be multiple ITEM7(Continue) in the file which will mess up the file. The loop will add them all together.
      do{
        $output7.=$all[++$i];
      } until($all[$i+1] =~ m/^ITEM 7a$/s
            or $all[$i+1] =~ m/^ITEM 8$/s
            or $all[$i+1] =~ m/^ITEM 9$/s);
    }
    elsif($all[$i] =~ m/^ITEM 7a$/s){
      $exist7a=1;
      do{
        $output7a.=$all[++$i];
      } until($all[$i+1] =~ m/^ITEM 8$/s
            or $all[$i+1] =~ m/^ITEM 9$/s);
    }
  }
}

# Output to 3 individual files.
$fileout=$filename."_out";
$item7file=$filename."_7";
$item7afile=$filename."_7a";
open (FILEOUT, "> $fileout");
print FILEOUT $plainTextInOneLine;
close FILEOUT;
if($exist7){
  open (ITEM7, "> $item7file");
  print ITEM7 "ITEM 7. MANAGEMENT'S DISCUSSION AND ANALYSIS OF FINANCIAL CONDITION AND RESULTS OF OPERATIONS\n\n";
  print ITEM7 $output7;
  close ITEM7;
  print "Item 7 output to file: $item7file.\n";
}
else{
  print "Item 7 in $filename not found, error!\n";
}
if($exist7a){
  open (ITEM7A, "> $item7afile");
  print ITEM7A "ITEM 7A. QUANTITATIVE AND QUALITATIVE DISCLOSURES ABOUT MARKET RISK\n\n";
  print ITEM7A $output7a;
  close ITEM7A;
  print "Item 7a output to file: $item7afile.\n";
}
else{
  print "Item 7a in $filename not found.\n";
}
