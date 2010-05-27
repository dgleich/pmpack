function [X,errz] = pseudospectral(iAb,s,p_order,varargin)
% PSEUDOSPECTRAL
%
% Example:
%
% Copyright, Stanford University, 2009
% Paul G. Constantine, David F. Gleich

if nargin<3, error('Not enough input arguments.'); end

dim=length(s); % dimension

% set default values
ptol=0;
parallel=0;
convtype='relerr'; % types: relerr, mincoeff, resid
refsoln=[];
matfun=[];
vecfun=[];
matvecfun=[];

errz=[];

for i=1:2:(nargin-3)
    switch lower(varargin{i})
        case 'ptol'
            ptol=varargin{i+1};
        case 'parallel'
            parallel=varargin{i+1};
        case 'convtype'
            convtype=lower(varargin{i+1});
        case 'refsoln'
            refsoln=varargin{i+1};
        case 'matfun'
            matfun=varargin{i+1};
        case 'vecfun'
            vecfun=varargin{i+1};
        case 'matvecfun'
            matvecfun=varargin{i+1};
        otherwise
            error('Unrecognized option: %s\n',varargin{i});
    end
end

% Check to see whether or not we do a convergence study.
if isnumeric(p_order)
    if ptol~=0, warning('The specified polynomial tolerance will be ignored.'); end
    if isscalar(p_order) 
        p_order=p_order*ones(dim,1); 
    else
        if max(size(p_order))~=dim, error('Tensor order must equal dimension.'); end
    end
elseif isequal(p_order,'adapt')
    if ptol==0, ptol=1e-8; end
else
    error('Unrecognized option for p_order: %s\n',p_order);
end

if isequal(p_order,'adapt')
    if isequal(convtype,'mincoeff') && ~isempty(refsoln)
        warning('Reference solution will be ignored.');
    end
    
    if isempty(refsoln)
        refsoln=pseudospectral(iAb,s,0,...
            'parallel',parallel,'matfun',matfun,'vecfun',vecfun,'matvecfun',matvecfun);
    end
    
    err=inf; order=1;
    while err>ptol
        X=pseudospectral(iAb,s,order,...
            'parallel',parallel,'matfun',matfun,'vecfun',vecfun,'matvecfun',matvecfun);
        err=error_estimate(convtype,X,refsoln);
        errz(order)=err;
        order=order+1;
        if isequal(convtype,'relerr'), refsoln=X; end
    end
else
    % Construct the array of dim dimensional gauss points and the eigenvector
    % matrix of the multivariate Jacobi matrix.
    Q=cell(dim,1);
    q0=1;
    for i=1:dim
        Q{i}=jacobi_eigenvecs(s(i),p_order(i)+1);
        q0=kron(q0,Q{i}(1,:));
    end 
    p=gaussian_quadrature(s,p_order+1);
    
    % evaluate the first point, so we can get the size of the system
    u0 = q0(1)*iAb(p(1,:));
    N = size(u0,1);

    % Solve the parameterized matrix equation at each gauss point.
    gn=prod(p_order+1);
    Uc=zeros(N,gn);
    U=zeros(size(Uc));
    Uc(:,1) = u0;
    if parallel
        parfor i=2:gn
            Uc(:,i) = q0(i)*iAb(p(i,:));
        end

        % Change of basis to the orthonormal basis.
        parfor i=1:N
            x=Uc(i,:);
            t=kronmult(Q,x');
            U(i,:)=t';
        end

    else
        for i=2:gn
            Uc(:,i) = q0(i)*iAb(p(i,:));
        end

        % Change of basis to the orthonormal basis.
        for i=1:N
            x=Uc(i,:);
            t=kronmult(Q,x');
            U(i,:)=t';
        end

    end

    % Construct the coefficients with the basis labels.
    X.coefficients=U; 
    X.index_set=index_set('tensor',p_order);
    X.variables=s; 
    X.fun=iAb;
    X.matfun=matfun;
    X.vecfun=vecfun;
    X.matvecfun=matvecfun;
    X=sort_bases(X);
end

end


