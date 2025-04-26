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
lut_path = os.path.join(studydir, "code", "NENAH-BIDS", "label_names", "fs_thomas-thalamic_LUT-mrtrix3.txt")
output_path = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "NBS", "results", "fs-thomas_whole_brain_connectome", "2-5_fs-thomas_whole_brain_connectome_significant_connections.txt")

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
    (5, 9, 2.51),
    (16, 22, 2.70),
    (9, 24, 2.68),
    (22, 24, 2.70),
    (12, 34, 2.52),
    (13, 34, 3.38),
    (16, 35, 2.86),
    (21, 35, 2.54),
    (23, 35, 2.61),
    (27, 36, 2.58),
    (9, 39, 2.70),
    (24, 39, 2.55),
    (16, 48, 2.61),
    (48, 50, 2.67),
    (26, 53, 2.72),
    (53, 54, 2.80),
    (50, 56, 2.73),
    (36, 57, 2.77),
    (47, 59, 3.07),
    (52, 59, 2.70),
    (36, 60, 2.59),
    (59, 60, 2.77),
    (37, 61, 2.78),
    (59, 61, 2.73),
    (46, 65, 2.80),
    (12, 68, 2.55),
    (53, 68, 2.76),
    (57, 68, 2.60),
    (20, 71, 2.86),
    (34, 71, 2.58),
    (27, 72, 2.92),
    (34, 72, 3.11),
    (27, 73, 2.72),
    (9, 74, 3.07),
    (71, 74, 2.60),
    (68, 76, 2.93),
    (72, 76, 2.60),
    (44, 77, 2.67),
    (36, 78, 2.50),
    (61, 78, 3.16),
    (59, 79, 2.90),
    (61, 79, 2.92),
    (68, 80, 2.92),
    (77, 80, 3.16),
    (78, 80, 3.90),
    (79, 80, 3.11),
    (68, 82, 3.64),
    (78, 82, 3.19),
    (18, 83, 2.52),
    (31, 83, 2.53),
    (71, 83, 3.14),
    (27, 84, 3.54),
    (35, 84, 2.93),
    (65, 87, 2.55),
    (73, 87, 2.61),
    (77, 87, 3.58),
    (13, 88, 2.72),
    (36, 88, 2.95),
    (61, 88, 3.56),
    (26, 89, 2.75),
    (36, 89, 2.67),
    (39, 89, 3.02),
    (77, 89, 2.63),
    (36, 90, 2.57),
    (59, 90, 2.54),
    (68, 90, 2.78),
    (77, 90, 2.80),
    (79, 90, 2.74)
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