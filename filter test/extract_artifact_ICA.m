function artifact_across_chan = extract_artifact_ICA(pulse_chan_data, stim_chans, numComponents, numNeighbor, chanMap)
    
    
    if isempty(chanMap)
        chanMap = 'ImecPrimateStimRec128_kilosortChanMap.mat';
    end
    load(chanMap, 'xcoords', 'ycoords');
    points = [xcoords, ycoords];
    [neighbors,~] = knnsearch(points, points,'K',numNeighbor,'Distance','chebychev');
    artifact_across_chan = pulse_chan_data;
    for i = 1:128
        [whitened_chan, mu, invM, ~] = whiten(pulse_chan_data(:, neighbors(i, :)), 1e-6);
        ricaModel = rica(whitened_chan, numComponents, 'NonGaussianityIndicator', ones(1, numComponents) );
        W = ricaModel.TransformWeights;  % Size: (numComponents x 77)

        % Transform data into independent components
        S = transform(ricaModel, whitened_chan);
        % S = pulse_chan_data(:, neighbors(i, :))*pinv(W');
       

        weights = sum(abs(W), 1);
        [~, artifactidx] = maxk(weights,1);
        % S(:,artifactidx) = 0;
        % figure
        % subplot(3,1,1)
        % plot(S(:,artifactidx)*W(1, artifactidx)')
        % title('weighted')
        % subplot(3,1,2)
        % plot(S(:,artifactidx))
        % title('source')
        % subplot(3,1,3)
        % plot(S*W')
        % title('mixed')
        temp = repmat(mu, length(S), 1);
        mixed_artifact = (S(:,artifactidx)*W(:,artifactidx)')*invM+temp;
        % figure
        % plot(pulse_chan_data(1:300, neighbors(i, 2)))
        % hold on
        % plot(mixed_artifact(1:300,2), 'LineWidth',2.0)
        % hold off

        
        artifact_across_chan(:, i) = mixed_artifact(:, 1);
    end
        % Get the transformation matrix (weights)
    
end