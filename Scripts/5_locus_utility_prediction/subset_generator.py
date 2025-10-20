'''
A script to generate subsets of loci
based on model predictions and random
'''
import pandas as ps
import sys
import random
import argparse


def generate_subsets(dataset, current_ds, option):
    '''
    Generate subsets based on the option
    '''
    dataset_sorted = sorted(dataset.keys(), key=dataset.get)
    if option == "bwr":
        print(dataset.keys())
        #generate subsets of best, worst, and random
        #this option is used for simulation datasets
        with open(current_ds+"_worst600.txt", "w") as outh:
            for key in dataset_sorted[:600]:
                print(key, file=outh)
        dataset_sorted.reverse()
        with open(current_ds+"_best800.txt", "w") as outh:
            for key in dataset_sorted[:800]:
                print(key, file=outh)
        with open(current_ds+"_best600.txt", "w") as outh:
            for key in dataset_sorted[:600]:
                print(key, file=outh)
        for rid in range(4):
            with open(current_ds+"_random"+str(rid)+".txt", "w") as outh:
                for key in random.sample(list(dataset), 600):
                    print(key, file=outh)
    else:
        #generate incremental subsets (10% step)
        #this option is used for empirical datasets
        binsize = len(dataset_sorted)/10
        with open(current_ds+"_worst10.txt", "w") as outh:
            for key in dataset_sorted[:round(binsize*1)]:
                print(key, file=outh)
        with open(current_ds+"_best10.txt", "w") as outh:
            for key in dataset_sorted[round(binsize*9):]:
                print(key, file=outh)
        with open(current_ds+"_best60.txt", "w") as outh:
            for key in dataset_sorted[round(binsize*4):]:
                print(key, file=outh)
        with open(current_ds+"_best70.txt", "w") as outh:
            for key in dataset_sorted[round(binsize*3):]:
                print(key, file=outh)
        with open(current_ds+"_best80.txt", "w") as outh:
            for key in dataset_sorted[round(binsize*2):]:
                print(key, file=outh)
        with open(current_ds+"_best90.txt", "w") as outh:
            for key in dataset_sorted[round(binsize*1):]:
                print(key, file=outh)


def main():
    '''
    The main function
    '''
    parser = argparse.ArgumentParser(description='Generate subsets of loci '+
                '(for simulated datasets use -s bwr, for empirical use -s i)',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser._action_groups.pop()
    required = parser.add_argument_group('required arguments')

    required.add_argument('-i', metavar='table', help='input table file',
                            dest="locus_data", required=True)
    required.add_argument('-s', choices=['bwr','i'],
                            help='subset type: bwr (best 800 and 600, '+
                            'worst 600, and 5 random 600), i ('+
                            'best 10%%, worst 10%%, incremental 10%%)',
                            dest="option", required=True)
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit()
    else:
        args = parser.parse_args()

        contig_data = ps.read_csv(vars(args)["locus_data"], sep=',')
        option = vars(args)["option"]

        random.seed(12345)

        #pass through the data frame, call subset generator
        current_ds = None
        dataset = {}
        for index, row in contig_data.iterrows():
            splitcol1 = row[0].split("_")
            if splitcol1[0] == "ds":
                dsname = "_".join(splitcol1[0:2])
                locname = "_".join(splitcol1[2:])
            else:
                dsname = splitcol1[0]
                locname = "_".join(splitcol1[1:])
            #new dataset detected - call generator for previous
            if current_ds != dsname and current_ds != None:
                print("generate subsets for", current_ds)
                generate_subsets(dataset, current_ds, option)
                dataset = {}
            dataset[locname] = row[1]
            current_ds = dsname
        #call generator for the last dataset
        print("generate subsets for", current_ds)
        generate_subsets(dataset, current_ds, option)


if __name__ == "__main__":
    main()
