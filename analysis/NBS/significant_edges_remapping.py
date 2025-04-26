import os

def read_lut(lut_path):
    """
    Reads a LUT file with each line formatted as:
        index    region_name
    and returns a dictionary mapping indices to region names.
    """
    lut = {}
    with open(lut_path, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip empty lines or comment lines.
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            try:
                index = int(parts[0])
                # Join the remaining parts in case the region name contains spaces.
                region = " ".join(parts[1:])
                lut[index] = region
            except ValueError:
                # If the first token isn't an integer, skip this line.
                continue
    return lut


# update these paths accordingly:
studydir = os.getcwd()
lut_path = os.path.join(studydir, "code", "NENAH-BIDS", "label_names", "fs-ctx_thomas-thalamic-nuclear-groups_LUT-mrtrix3.txt")
output_path = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "NBS", "results", "fs-ctx_thomas_nuclear_groups_connectome", "2-8_threshold_thalamus_lobes_significant_connections.txt")

# list of significant edges: (source index, target index, test statistic)
# these are obtained by running this script in the MATLAB terminal after running the NBS:
# global nbs;
# [i, j] = find(nbs.NBS.con_mat{1});
# for n = 1:length(i)
#     stat = nbs.NBS.test_stat(i(n), j(n));
#     fprintf('    (%d, %d, %.2f),\n', i(n), j(n), stat);
# end

# todo: write script to extract edges from matlab

edges = [
    (53, 68, 2.82),
    (57, 68, 3.02),
    (68, 73, 2.95),
    (36, 74, 2.99),
    (61, 74, 3.76),
    (68, 74, 2.88),
    (68, 75, 3.30),
    (68, 76, 4.05),
]

# --- Process LUT and map edges ---
lut = read_lut(lut_path)

results = []
results.append("Significant Connections:\n")
for src, tgt, stat in edges:
    src_region = lut.get(src, f"Unknown({src})")
    tgt_region = lut.get(tgt, f"Unknown({tgt})")
    line = f"Edge: {src_region} ({src}) to {tgt_region} ({tgt}). Test stat: {stat:.2f}"
    results.append(line)

# --- Save the results to output file ---
with open(output_path, "w") as out_file:
    out_file.write("\n".join(results))

print(f"Significant connections saved to: {output_path}")