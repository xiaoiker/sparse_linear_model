function [Vec meanSample] = trainPCA(trainFeatures, trainLabels, ReducedDim)
%% set options
if (nargin < 3),
	ReducedDim = 10;
else
	if (~isscalar(ReducedDim)),
		error('ReducedDim is not scalar. May have passed semiSplit instead of ReducedDim.');
	end;
end;

%% use PCA
options = [];
options.ReducedDim = ReducedDim;				% number of dimensions
[Vec foo meanSample] = PCA(trainFeatures, options);
