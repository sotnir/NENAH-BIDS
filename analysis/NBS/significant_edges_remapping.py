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
output_path = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "NBS", "results", "fs-ctx_thomas_nuclear_groups_connectome", "2-5_threshold_thalamus_lobes_significant_connections.txt")

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
    (5, 9, 2.75),
    (9, 15, 3.11),
    (16, 22, 2.72),
    (9, 24, 2.64),
    (22, 24, 2.70),
    (12, 34, 2.81),
    (13, 34, 2.88),
    (23, 34, 2.75),
    (27, 34, 2.95),
    (16, 35, 2.86),
    (21, 35, 2.54),
    (23, 35, 2.61),
    (27, 36, 2.59),
    (21, 46, 2.80),
    (16, 48, 2.61),
    (48, 50, 2.67),
    (26, 53, 2.72),
    (53, 54, 2.80),
    (37, 56, 2.78),
    (50, 56, 2.73),
    (36, 57, 2.72),
    (52, 59, 2.71),
    (36, 60, 2.69),
    (59, 60, 2.77),
    (37, 61, 2.78),
    (59, 61, 2.71),
    (46, 68, 2.57),
    (53, 68, 2.82),
    (54, 68, 2.65),
    (57, 68, 3.02),
    (61, 68, 2.63),
    (27, 70, 4.03),
    (35, 70, 2.58),
    (65, 73, 2.55),
    (68, 73, 2.95),
    (36, 74, 2.99),
    (61, 74, 3.76),
    (68, 74, 2.88),
    (26, 75, 2.66),
    (68, 75, 3.30),
    (36, 76, 2.59),
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