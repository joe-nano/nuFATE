function [w,v,ci,energy_nodes] = cascade(varargin) %this is get_eigs
flavor = varargin{1};
% defaults:
g = 2;
logemin = 3; %Min log energy (GeV) (do not touch unless you have recomputed cross sections)
logemax = 10; % Max log E
NumNodes = 200;



if nargin >= 2
    g = varargin{2};
end
if nargin >= 3 %you shouldn't be specifying only one of these:
    logemin = varargin{3};
    logemax = varargin{4};
    NumNodes = varargin{5};
end

%get cross section locations
if flavor==-1
    sigma_fname = '/total_cross_sections/nuebarxs';
elseif flavor == -2
    sigma_fname = '/total_cross_sections/numubarxs';
elseif flavor == -3
    sigma_fname = '/total_cross_sections/nutaubarxs';
elseif flavor == 1
    sigma_fname = '/total_cross_sections/nuexs';
elseif flavor == 2
    sigma_fname = '/total_cross_sections/numuxs';
elseif flavor == 3
    sigma_fname = '/total_cross_sections/nutauxs';
end
if flavor > 0
    dxs_fname = '/differential_cross_sections/dxsnu';
else
    dxs_fname = '/differential_cross_sections/dxsnubar';
end

energy_nodes = logspace(logemin,logemax,NumNodes);
[RHSMatrix, sigma_array] = get_RHS_matrices(energy_nodes,sigma_fname,dxs_fname);
if flavor ==-3
    [RHregen,~] = get_RHS_matrices(energy_nodes,sigma_fname,'/tau_decay_spectrum/tbarfull');
    RHSMatrix = RHSMatrix + RHregen;
elseif flavor == 3
    [RHregen,~] = get_RHS_matrices(energy_nodes,sigma_fname,'/tau_decay_spectrum/tfull');
    RHSMatrix = RHSMatrix + RHregen;
end

phi_0 = energy_nodes.^(2-g)';
[v,w] = eig(-diag(sigma_array) + RHSMatrix);
ci = (v^-1)*phi_0;
w = diag(w);

end

function  [RHSMatrix, sigma_array] = get_RHS_matrices(energy_nodes,sigma_fname,dxs_fname)
h5flag = 1; %this flag tells the code to read the HDF5 table, rather than a plain text file. It can be turned off here for legacy/comparison purposes
NumNodes = length(energy_nodes);
if h5flag
    %note the transpose ('): this is due to the way the h5 file is indexed
    sigma_array = h5read('../data/NuFATECrossSections.h5',sigma_fname)';
    dsigmady = h5read('../data/NuFATECrossSections.h5', dxs_fname)';    
else
    sigma_array = load(['../data' sigma_fname '.dat']);
    dsigmady = load(['../data' dxs_fname '.dat']);
end
DeltaE = diff(log(energy_nodes));
RHSMatrix = zeros(NumNodes);
for i = 1:NumNodes
    for j = i+1:NumNodes
        RHSMatrix(i,j) = DeltaE(j-1)*dsigmady(j,i)*energy_nodes(j).^-1*energy_nodes(i).^2;
    end
end
end