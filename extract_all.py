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
    if "7 outputted" in respond:
      suc7+=1
      suc7list.append(file)
    if "7a outputted" in respond:
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

print "Total file: ", total
print "Success I7: ", suc7
print "Success I7A:", suc7a
print "I7 is fina: ", fina
print "Fail files: ", len(faillist)

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
