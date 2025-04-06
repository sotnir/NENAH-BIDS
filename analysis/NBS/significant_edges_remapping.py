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

# --- User settings ---
# update these paths accordingly:
studydir = os.getcwd()
lut_path = os.path.join(studydir, "code", "NENAH-BIDS", "label_names", "fs_thomas-thalamic_2_fs-lobes_thomas-thalamic-nuclear-groups_convert-mrtrix3.txt")
output_path = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "NBS", "results",  "thalamus_lobes_significant_connections.txt")

# list of significant edges: (source index, target index, test statistic)
# these are obtained by running this script in the MATLAB terminal after running the NBS:
# >> global nbs;
# [i, j] = find(nbs.NBS.con_mat{1});
# for n = 1:length(i)
#     % Use node labels if available; otherwise, use indices
#     if isfield(nbs.NBS, 'node_label') && ~isempty(nbs.NBS.node_label)
#         i_lab = nbs.NBS.node_label{i(n)};
#         j_lab = nbs.NBS.node_label{j(n)};
#     else
#         i_lab = num2str(i(n));
#         j_lab = num2str(j(n));
#     end
#     stat = nbs.NBS.test_stat(i(n), j(n));
#     fprintf('Edge: %s to %s. Test stat: %0.2f\n', i_lab, j_lab, stat);
# end

edges = [
    (1, 5, 3.36),
    (2, 5, 3.61),
    (1, 7, 2.21),
    (1, 10, 3.10),
    (1, 12, 2.40),
    (9, 12, 2.15),
    (10, 14, 4.02),
    (7, 15, 2.77),
    (11, 15, 2.14),
    (1, 17, 2.62),
    (7, 17, 2.58),
    (11, 17, 2.36),
    (7, 18, 2.04),
    (8, 19, 4.02),
    (1, 20, 2.34),
    (8, 20, 2.55),
    (8, 21, 2.29),
    (8, 22, 3.67)
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