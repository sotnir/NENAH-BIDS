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
lut_path = os.path.join(studydir, "code", "NENAH-BIDS", "label_names", "fs-lobes_thomas-thalamic-nuclear-groups_LUT-mrtrix3.txt")
output_path = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "NBS", "results", "thalamus_lobes_connectome", "2-5_threshold_thalamus_lobes_significant_connections.txt")

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
    (1, 5, 3.36),
    (2, 5, 3.61),
    (1, 10, 3.10),
    (10, 14, 4.02),
    (7, 15, 2.77),
    (1, 17, 2.62),
    (7, 17, 2.58),
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