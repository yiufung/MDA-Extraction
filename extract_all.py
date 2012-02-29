#!/usr/bin/local/python
# Helper script to run the extract.pl on every file under current directory.
# Optional: Output to corresponding directory.
import os, sys, commands, shutil

files=os.listdir(os.getcwd())
total=0
suc7=0
suc7a=0
fina=0
suc7list=[]
suc7alist=[]
finalist=[]
faillist=[]
for file in files:
  if file.endswith(".txt"):
    total+=1
    respond=commands.getoutput("perl extract.pl "+file)
    if "Invalid" in respond:
      fina+=1
      finalist.append(file)
    if "mda outputted" in respond:
      suc7+=1
      suc7list.append(file)
    if "quant outputted" in respond:
      suc7a+=1
      suc7alist.append(file)

for x in files:
  if ".txt" in x:
    faillist.append(x)
for x in finalist:
  if x in faillist:
    faillist.remove(x)
for x in suc7list:
  if x in faillist:
    faillist.remove(x)
for x in suc7alist:
  if x in faillist:
    faillist.remove(x)

print "Total files: ", total
print "mda: ", suc7
print "quantitative:", suc7a
print "financial statements: ", fina
print "Fail files: ", len(faillist)

# uncomment if you want detailed statistics
#total_left = len(faillist)+fina+suc7
#pass=fina+suc7
#print "\n"
#print "Fail + I7 financial + I7 Extracted = ", total_left
#print "Pass files = I7 Extracted + I7 financial = ", pass
#print "Pass rate = ", float(pass)/float(total_left)
#print "I7 rate = I7 / Pass files = ", float(suc7)/float(pass)
#print "I7A rate = I7A / Pass files = ", float(suc7a)/float(pass)

#var=raw_input("Output files to corresponding directory?[Y/N]:")
#if var == "Y" or var == "y":
os.mkdir("suc7")
os.mkdir("suc7a")
os.mkdir("fail")
os.mkdir("fina")
for file in suc7list:
  shutil.copy(file+"_7", "suc7/")
for file in suc7alist:
  shutil.copy(file+"_7a", "suc7a/")
for file in faillist:
  shutil.copy(file+"_out", "fail/")
for file in finalist:
  shutil.copy(file+"_out", "fina/")
