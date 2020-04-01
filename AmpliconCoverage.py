import sys
import csv

def get_filename_stub(this_name, this_ext):
    this_stub = this_name

    this_pos = this_name.rfind(this_ext)
    if this_pos > 0:
        this_stub = this_name[:this_pos]

    return this_stub


def calculate_coverage(primer_filename, depth_filename):

    print("Primer bed file: " + primer_filename)
    print("samtools depth file: " + depth_filename)
    outfilename=get_filename_stub(depth_filename, ".") + "_amplicon_depth.txt"
    print("output amplicon file: " + outfilename)

    print("Reading in primers")

    primers = []
    with open(primer_filename) as file_handler:
        reader = csv.reader(file_handler, delimiter='\t')

        for row in reader:

            # primer_ref = row[0]
            primer_start = int(row[1])
            primer_end = int(row[2])
            primer_name = row[3]
            # primer_pool = row[4]

            primer_name_list = primer_name.split("_")
            primer_set = int(primer_name_list[1])
            primer_lr = primer_name_list[2]

            if primer_lr != "LEFT" and primer_lr != "RIGHT":
                print("Warning primer does not equal LEFT OR RIGHT: " + row)

            # print(primer_name + " " + str(primer_set) + " " + primer_lr)

            # bed is 0 indexed
            # example: nCoV-2019_1_LEFT: 30 54
            # The primer actually starts at 31 and actually ends at 54
            # 31 as zero indexed so 30 +1 = 31
            # 54 as believe bed ends are +1, so the -1 0 offset and the +1 extra cancel out
            primers.append([primer_set, primer_start, primer_end, primer_lr, primer_name])

    print("Number of primers = " + str(len(primers)))

    print("Creating primer trimmed amplicon pairs")
    primer_sets = {}
    for primer in primers:
        if primer[0] in primer_sets:

            temp_set = primer_sets[primer[0]]

            if primer[3] == "LEFT":
                if temp_set[0] != -1:
                    print("Warning primer LEFT already set for this set:")
                    print(primer)

                    # LEFT - We want to have the amplicon not covered by any primers, so we take the highest LEFT end as amplicon start
                    if primer[2]+1 > temp_set[0]:
                        temp_set[0] = primer[2]+1

                    if primer[1]+1 < temp_set[2]:
                        temp_set[2] = primer[1]+1

                else:
                    temp_set[0] = primer[2]+1
                    temp_set[2] = primer[1]+1

            elif primer[3] == "RIGHT":
                if temp_set[1] != -1:
                    print("Warning primer LEFT already set for this set:")
                    print(primer)

                    # RIGHT - We want to have the amplicon not covered by any primers, so we take the lowest RIGHT START as amplicon end
                    if primer[1] < temp_set[1]:
                        temp_set[1] = primer[1]

                    if primer[2] > temp_set[3]:
                        temp_set[3] = primer[2]
                else:
                    temp_set[1] = primer[1]
                    temp_set[3] = primer[2]

            primer_sets[primer[0]] = temp_set

        else:
            # For LEFT primers we want the primer_end +1 as we want the first non primer base
            if primer[3] == "LEFT":
                primer_sets[primer[0]] = [primer[2]+1, -1, primer[1]+1, -1]
            # For Right primers we want the primer_start - no need to adjust as 0 index means this is the first non primer base
            elif primer[3] == "RIGHT":
                primer_sets[primer[0]] = [-1, primer[1], -1, primer[2]]

    #for primer_set in primer_sets:
    #    print(primer_set, ":", primer_sets[primer_set])

    print("Creating non-overlapping amplicon genome sections")
    amplicons = {}
    for primer_set in primer_sets:
        temp_set = [primer_sets[primer_set][0], primer_sets[primer_set][1]]
        prev_set = primer_set - 1
        next_set = primer_set + 1

        if prev_set in primer_sets:
            # this sets  starts where the previous set ends (+1)
            temp_set[0] = primer_sets[prev_set][3] + 1
        if next_set in primer_sets:
            # this sets end starts where the next set starts (-1)
            temp_set[1] = primer_sets[next_set][2] - 1

        amplicons[primer_set] = temp_set

    #for primer_set in amplicons:
    #    print(primer_set, ":", amplicons[primer_set])

    depth = {}
    with open(depth_filename) as file_handler:
        reader = csv.reader(file_handler, delimiter='\t')

        for row in reader:
            depth[int(row[1])] = int(row[2])

    with open(outfilename, "w") as file_output:
        file_output.write("AmpliconN\tTrimStart\tTrimEnd\tLength\tAverage-Cov\tZero-Cov\t<10-Cov\t<20-Cov\n")

        for amplicon in amplicons:
            region = range(amplicons[amplicon][0], amplicons[amplicon][1]+1, 1)
            sites = 0
            coverage = 0
            zero = 0
            ten = 0
            twenty = 0

            for pos in region:
                sites += 1
                coverage += depth[pos]

                if depth[pos] == 0:
                    zero += 1
                if depth[pos] < 20:
                    twenty += 1
                if depth[pos] < 10:
                    ten += 1

            average_coverage = float(coverage)/sites

            file_output.write(str(amplicon) + "\t" + str(amplicons[amplicon][0]) + "\t" + str(amplicons[amplicon][1]) + "\t" + str(sites) + "\t" + str(average_coverage) + "\t" + str(zero) + "\t" + str(ten) + "\t" + str(twenty) + "\n")


print("AmpliconCoverage.py started...\n")

arguments = len(sys.argv)

if arguments < 3:
    print("Error - incorrect number of arguments [" + str(arguments) + "] - example usage:")
    print("AmpliconCoverage.py primer.bed samtools_depth.txt")
    print("Exiting...")
    sys.exit(1)

calculate_coverage(sys.argv[1], sys.argv[2])

print("\n...finished AmpliconCoverage.py")
