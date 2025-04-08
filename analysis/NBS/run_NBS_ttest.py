import os
import argparse
import subprocess
import tempfile

def read_lut(lut_path):
    lut = {}
    with open(lut_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            try:
                index = int(parts[0])
                region = " ".join(parts[1:])
                lut[index] = region
            except ValueError:
                continue
    return lut

def build_ui_struct(connectome_path, design_path, contrast, size_method, threshold):
    return f"""
    UI.method.ui='Run NBS';
    UI.test.ui='t-test';
    UI.size.ui='{size_method}';
    UI.thresh.ui='{threshold}';
    UI.perms.ui='5000';
    UI.alpha.ui='0.05';
    UI.contrast.ui='{contrast}';
    UI.design.ui='{design_path}';
    UI.exchange.ui='';
    UI.matrices.ui='{connectome_path}';
    UI.node_label.ui='';
    UI.node_coor.ui='';
    """

def run_matlab_script(script_text):
    with tempfile.NamedTemporaryFile(delete=False, suffix=".m", mode='w') as f:
        f.write(script_text)
        temp_script_path = f.name
    cmd = f"matlab -batch \"run('{temp_script_path}')\""
    subprocess.run(cmd, shell=True)
    os.remove(temp_script_path)

def parse_nbs_output():
    # this assumes the `global nbs` variable exists after running the script
    # and that it writes a file `nbs_edges_temp.txt` from within MATLAB
    edges = []
    try:
        with open("nbs_edges_temp.txt", "r") as f:
            for line in f:
                line = line.strip().strip(",")
                if not line:
                    continue
                parts = line.strip("()").split(",")
                i, j, stat = int(parts[0]), int(parts[1]), float(parts[2])
                edges.append((i, j, stat))
        os.remove("nbs_edges_temp.txt")
    except FileNotFoundError:
        pass
    return edges

def save_results(threshold, connectome_name, edges, lut, method, out_dir):
    filename = f"{threshold}_threshold_{connectome_name}_{method}.txt"
    filepath = os.path.join(out_dir, filename)
    result_lines = [
        f"Significant Connections for {threshold}:\n"
    ]
    for i, j, stat in edges:
        i_lab = lut.get(i, f"Unknown({i})")
        j_lab = lut.get(j, f"Unknown({j})")
        result_lines.append(f"Edge: {i_lab} ({i}) to {j_lab} ({j}). Test stat: {stat:.2f}")
    with open(filepath, "w") as f:
        f.write("\n".join(result_lines))
    print(f"Saved results to {filepath}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--connectome_path', type=str, required=False, default='/data/iridis/NENAH_BIDS/code/NENAH-BIDS/analysis/NBS/connectivity_matrices/thalamus_lobes_connectome/NENAH002.txt')
    parser.add_argument('--LUT', type=str, required=False, default='/data/iridis/NENAH_BIDS/code/NENAH-BIDS/label_names/fs-lobes_thomas-thalamic-nuclear-groups_LUT-mrtrix3.txt')
    parser.add_argument('--threshold', nargs='*', type=float, default=['2.5', '2.6', '2.7', '2.8', '2.9', '3.0'])
    parser.add_argument('--contrast_vector', type=str, default='[0,-1]')
    parser.add_argument('--design_matrix', type=str, default='/data/iridis/NENAH_BIDS/code/NENAH-BIDS/analysis/NBS/design_matrices/design_matrix_ttest.txt')
    parser.add_argument('--output_dir', type=str, default='/data/iridis/NENAH_BIDS/code/NENAH-BIDS/analysis/NBS/results/thalamus_lobes_connectome')
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)
    lut = read_lut(args.LUT)
    connectome_name = os.path.splitext(os.path.basename(args.connectome_path))[0]

    for thresh in args.threshold:
        for size in ['Extent', 'Intensity']:
            matlab_code = build_ui_struct(
                args.connectome_path,
                args.design_matrix,
                args.contrast_vector,
                size,
                thresh,
            )
            matlab_code2 = """
            global nbs;
            [i,j]=find(nbs.NBS.con_mat{1});
            fid = fopen('nbs_edges_temp.txt','w');
            for n=1:length(i)
                fprintf(fid,'(%d, %d, %.2f),\\n', i(n), j(n), nbs.NBS.test_stat(i(n), j(n)));
            end
            fclose(fid);
            """
            subprocess.run(matlab_code, shell=True)
            run_matlab_script(matlab_code2)
            edges = parse_nbs_output()
            if edges:
                save_results(thresh, connectome_name, edges, lut, size.lower(), args.output_dir)
            else:
                print(f"No significant results for threshold {thresh} ({size})")

if __name__ == "__main__":
    main()
