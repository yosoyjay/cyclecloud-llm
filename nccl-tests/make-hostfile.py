#!python
from subprocess import check_output


def main(partition='hpc', hostfile='hostfile.txt'):
    # split header and partitions
    # PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
    # hpc*         up   infinite      2   idle slurm-hpc-pg0-[1-2]
    output_lines = check_output('sinfo').decode('utf-8').split('\n')
    for line in output_lines:
        if partition in line:
            break

    # Create list of nodes
    # expand node range (e.g. slurm-hpc-pg0-[1-10])
    node_list = line.split()[-1]
    # slurm-hpc-pg0-
    node_prefix = node_list.split('[')[0]
    # 1-10
    node_range = node_list.split('[')[1].strip(']')
    first_node, last_node = [int(val) for val in node_range.split('-')]

    # write hostfile
    with open(hostfile, 'w') as fout:
        for val in range(first_node, last_node + 1):
            fout.write(f'{node_prefix}{val}\n')


if __name__ == '__main__':
    main()
