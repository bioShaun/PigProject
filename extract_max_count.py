import pandas as pd
import os
import glob
import click


@click.command()
@click.argument(
    'count_dir',
    type=click.Path(exists=True),
    required=True,
)
def main(count_dir):
    count_files = os.listdir(count_dir)
    out_dict = dict()
    for each_file in count_files:
        if each_file.endswith('.counts'):
            count_file = os.path.join(
                count_dir, each_file)
            each_sample = each_file[:-7]
            count_df = pd.read_table(count_file, comment='#')
            colname = count_df.columns[-1]
            max_count = count_df.loc[:, colname].max()
            out_dict.setdefault('sample', []).append(each_sample)
            out_dict.setdefault('count', []).append(max_count)
    out_df = pd.DataFrame(out_dict)
    out_file = os.path.join(count_dir, 'sample.max.count.txt')
    out_df.to_csv(out_file, sep='\t', index=False, columns=['sample', 'count'])
    
if __name__ == '__main__':
    main()
