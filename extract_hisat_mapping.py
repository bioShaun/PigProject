from __future__ import print_function
import sys
import os
import glob


if len(sys.argv) != 2:
    out_inf = 'python {s} mapping_dir > mapping_stat'.format(s=sys.argv[0])
    print(out_inf)
    sys.exit(1)


def get_mapping_rate(logs):
    for each_log in logs:
        with open(each_log) as log_inf:
            for eachline in log_inf:
                if 'overall alignment rate' in eachline:
                    return eachline.split()[0]


mapping_dir = sys.argv[1]
samples = os.listdir(mapping_dir)
print("Sample\tMapping_rate")
for each_sample in samples:
    each_mapping_dir = os.path.join(mapping_dir, each_sample)
    each_mapping_log = glob.glob('{d}/{s}.log*'.format(
        d=each_mapping_dir, s=each_sample))
    if each_mapping_log:
        mapping_rate = get_mapping_rate(each_mapping_log)
        print('{s}\t{m}'.format(
            s=each_sample, m=mapping_rate))
        
