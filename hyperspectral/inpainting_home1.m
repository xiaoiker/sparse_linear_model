fileNames = {...
	'~/MATLAB/datasets_all/hyperspectral/moving/tif_files/lawgate3',...
	'~/MATLAB/datasets_all/hyperspectral/moving/tif_files/lawlibrary7',...
	'~/MATLAB/datasets_all/hyperspectral/moving/tif_files/yard3',...
	'~/MATLAB/datasets_all/hyperspectral/moving/tif_files/lawgate1',...
	'~/MATLAB/datasets_all/hyperspectral/moving/tif_files/lawlibrary5',...
	'~/MATLAB/datasets_all/hyperspectral/moving/tif_files/lawlibrary9',...
	'~/MATLAB/datasets_all/hyperspectral/moving/tif_files/lawlibrary10',...
	'~/MATLAB/datasets_all/hyperspectral/moving/tif_files/yard2',...
	'~/MATLAB/datasets_all/hyperspectral/moving/tif_files/yard5'...
	};

largeM = 1040;
largeN = 1392;
subsample = 3;
kappa = 0.1;

M = largeM / 2 ^ subsample;
N = largeN / 2 ^ subsample;

numFiles = length(fileNames);
for iterFiles = 1:numFiles,
	fprintf('Now running file %s, number %d out of %d.\n', fileNames{iterFiles}, iterFiles, numFiles);
	cube = getCube(sprintf('%s', fileNames{iterFiles}), 420:10:720);
	cube = cube / maxv(cube);

	cubedown = zeros(M, N, 31);
	for iter = 1:31,
		temp = gauss_pyramid(cube(:,:,iter), subsample + 1);
		cubedown(:,:,iter) = temp{end};
	end;
	[B A] = robust_pca_apg_mex(reshape(cubedown, [M * N, 31]), [], [], kappa);
	cube_background = reshape(B, [M N 31]);
	cube_foreground = reshape(A, [M N 31]);
	save(sprintf('robust_pca_kappa%g_%s_sub%d.mat', kappa,...
		fileNames{iterFiles}(54:end), subsample), 'cube_background', 'cube_foreground');
end;
