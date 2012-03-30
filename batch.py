#!/usr/bin/local/python
# Helper script to run extract.pl on every file under current directory.
# Optional: Output to corresponding directory.
import os, sys, commands, shutil

files=os.listdir(os.getcwd())

total=0
sucMDA=0
sucQuant=0
fina=0

sucMDAlist=[]
sucQuantlist=[]
finalist=[]
faillist=[]

approx_total=len(files)

for file in files:
  print "processing: ", file
  if file.endswith(".txt"):
    # a valid file.
    total+=1
    print "progress... ", float(total)/float(approx_total)*100, " %"

    respond=commands.getoutput("perl extract.pl "+file)
    if "Item 7: Financial statements" in respond:
      fina+=1
      finalist.append(file)
    if "mda outputted" in respond:
      sucMDA+=1
      sucMDAlist.append(file)
    if "quant outputted" in respond:
      sucQuant+=1
      sucQuantlist.append(file)

# all files into faillist. 
for x in files:
  if ".txt" in x:
    faillist.append(x)
# remove financial statements ones. 
for x in finalist:
  if x in faillist:
    faillist.remove(x)
# remove MDA ones.
for x in sucMDAlist:
  if x in faillist:
    faillist.remove(x)
# remove Quant ones.
for x in sucQuantlist:
  if x in faillist:
    faillist.remove(x)
    
#var=raw_input("Output files to corresponding directory?[Y/N]:")
#if var == "Y" or var == "y":
#mkdir for four directories.
os.mkdir("sucMDA")
os.mkdir("sucQuant")
os.mkdir("fail")
os.mkdir("fina")
# in fail and fina, it's most probable to improve. 
# prepare two folders to contain file for further improvements. 
os.mkdir("fail/ori")
os.mkdir("fina/ori")

# Will use test.txt as example below. 

print "processing MDA files..."
for file in sucMDAlist:
  splitor=file.rsplit('.', 1) # file = test.txt
  name=splitor[0] # name = test
  filehtml=name+".html" # filehtml = test.html
  filemda=file+"_mda" # filemda = test.txt_mda

  # copy html into sucMDA.
  shutil.copy(file, "sucMDA/"+filehtml) # sucMDA/test.html
  # move mda
  os.rename(filemda, "sucMDA/"+filemda) # sucMDA/test.txt_mda

print "processing Quantitative files..."
for file in sucQuantlist:
  splitor=file.rsplit('.', 1) # file = test.txt
  name=splitor[0] # name = test
  filequant=file+"_quant" # filequant = test.txt_quant

  # move quant
  os.rename(filequant, "sucQuant/"+filequant) # sucQuant/test.text_quant

# Only output plain text. 
print "processing Financial statements files..."
for file in finalist:
  splitor=file.rsplit('.', 1)
  name=splitor[0]
  filehtml=name+".html" # test.html
  fileplaintext=file+"_plaintext" # test.txt_plaintext

  # copy plaintext. 
  shutil.copy(file+"_plaintext", "fina/"+file+"_plaintext");
  # copy original text under fail/ori.
  shutil.copy(file, "fina/ori/"+file)
  # copy html. 
  shutil.copy(file, "fina/"+filehtml)

print "processing Fail files..."
for file in faillist:
  splitor=file.rsplit('.', 1)
  name=splitor[0]
  filehtml=name+".html" # test.html
  fileplaintext=file+"_plaintext" # test.txt_plaintext

  # copy plaintext
  shutil.copy(fileplaintext, "fail/"+fileplaintext)
  # copy html
  shutil.copy(file, "fail/"+filehtml)
  # copy original text
  shutil.copy(file, "fail/ori/"+file)

## write output 
result = open('result', 'w')
result.write("Total files: "+str(total)+"\n")
result.write("    # all files with .txt ending.\n")
result.write("mda: "+str(sucMDA)+"\n")
result.write("    # all mda. only consider Item 7 situation. \n")
result.write("quantitative:"+str(sucQuant)+"\n")
result.write("    # all quant. only consider Item 7A quant. \n")
result.write("financial statements: "+str(fina)+"\n")
result.write("    # will have improvements. \n")
result.write("Fail files: "+str(len(faillist))+"\n")
result.write("    # will have improvements. \n")

# uncomment if you want detailed statistics
# result.write("Fail + financial + Extracted = "+str(total_left)+"\n")
passFile=total-len(faillist)
result.write("Pass rate = "+str(float(passFile)/float(total)*100)+"\n")
result.write("passfiles = total - fail = "+str(passFile)+"\n")
result.write("MDA rate = MDA files / passfiles = "+str(float(sucMDA)/float(passFile)*100)+"\n")
# result.write("I7A rate = I7A / Pass files = "+str(float(sucQuant)/float(passFile)*100)+"\n")
result.close()

print "Done. Refer to result for more info. "

