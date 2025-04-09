% run_NBS.m
% Add path to NBS if needed

% Global var for output
global nbs

% --- Input paths ---
matrices_path = '/data/iridis/NENAH_BIDS/code/NENAH-BIDS/analysis/NBS/connectivity_matrices/thalamus_lobes_connectome/NENAH002.txt';
design_path = '/data/iridis/NENAH_BIDS/code/NENAH-BIDS/analysis/NBS/design_matrices/design_matrix_ttest.txt';
contrast = '[0,-1]';
node_coor_path = '';
node_label_path = '';

% --- Parameters ---
thresholds = [2.5, 3.0, 3.5, 4.0, 4.5];
sizes = {'Extent', 'Intensity'};
output_dir = '/data/iridis/NENAH_BIDS/code/NENAH-BIDS/analysis/NBS/results/thalamus_lobes_connectome';
if ~exist(output_dir, 'dir'); mkdir(output_dir); end

for t = 1:length(thresholds)
    for s = 1:length(sizes)
        UI.method.ui = 'Run NBS';
        UI.test.ui = 't-test';
        UI.size.ui = sizes{s};
        UI.thresh.ui = num2str(thresholds(t));
        UI.perms.ui = '5000';
        UI.alpha.ui = '0.05';
        UI.contrast.ui = contrast;
        UI.design.ui = design_path;
        UI.matrices.ui = matrices_path;
        UI.node_coor.ui = node_coor_path;
        UI.node_label.ui = node_label_path;
        UI.exchange.ui = '';  % Not used here

        
        fprintf('Running NBS: thresh=%.1f, size=%s\n', thresholds(t), sizes{s});
        NBSrun(UI);

        
        filename = sprintf('%s/NBS_t%.1f_%s.txt', output_dir, thresholds(t), lower(sizes{s}));
        fid = fopen(filename, 'w');
        if isempty(nbs.NBS.con_mat)
            fprintf(fid, 'No significant component.\n');
        else
            conmat = nbs.NBS.con_mat{1};
            [i, j] = find(conmat);
            fprintf(fid, 'i\tj\n');
            for k = 1:length(i)
                fprintf(fid, '%d\t%d\n', i(k), j(k));
            end
        end
        fclose(fid);
    end
end
