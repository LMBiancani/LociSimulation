import sys
import csv

pathfile = sys.argv[1]
if len(sys.argv) > 2:
	columns_to_exclude = sorted([int(x) for x in sys.argv[2:]], reverse=True)
	if 0 in columns_to_exclude or 1 in columns_to_exclude:
		print ("should not be removing columns 0 or 1")
		sys.exit()
else:
	columns_to_exclude = []

def output_line(line, handle, columns_to_exclude):
	if len(columns_to_exclude) > 0:
		for idx in columns_to_exclude:
			if idx < len(line):
				line.pop(idx)
	if "NA" not in line:
		rejoinedline = "\t".join(line)
		print(rejoinedline, file=handle)

print ("read path file")
dsdict = {}
with open(pathfile) as pathfilehandle:
	for line in pathfilehandle:
		dsdict[line.strip().split("/")[-2]] = line.strip()

print ("parsing tables...")
with open("combined_ML_tab.tsv", "w") as outhandle:
	headerB = True
	for dataset in dsdict:
		with open(dsdict[dataset]) as dshandle:
			reader = csv.reader(dshandle, delimiter='\t', quotechar='"')
			header = reader.__next__()
			if headerB:
				output_line(header, outhandle, columns_to_exclude)
				headerB = False
			for line in reader:
				line[0] = dataset+'_'+line[0]
				output_line(line, outhandle, columns_to_exclude)
print("done")