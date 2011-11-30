function [U,S,V,bnd,j] = lansvd_modified_nocomplex(varargin)

%LANSVD  Compute a few singular values and singular vectors.
%   LANSVD computes singular triplets (u,v,sigma) such that
%   A*u = sigma*v and  A'*v = sigma*u. Only a few singular values
%   and singular vectors are computed  using the Lanczos
%   bidiagonalization algorithm with partial reorthogonalization (BPRO).
%
%   S = LANSVD(A)
%   S = LANSVD('Afun','Atransfun',M,N)
%
%   Stephen Becker says: WARNING!  If the output is just S, and not
%   [U,S,V], then less re-orthogonalization is done, and the output can be
%   very inaccurate!  Use with care.
%
%   The first input argument is either a  matrix or a
%   string containing the name of an M-file which applies a linear
%   operator to the columns of a given matrix.  In the latter case,
%   the second input must be the name of an M-file which applies the
%   transpose of the same operator to the columns of a given matrix,
%   and the third and fourth arguments must be M and N, the dimensions
%   of the problem.
%
%   [U,S,V] = LANSVD(A,K,'L',...) computes the K largest singular values.
%
%   [U,S,V] = LANSVD(A,K,'S',...) computes the K smallest singular values.
%
%   The full calling sequence is
%
%   [U,S,V] = LANSVD(A,K,SIGMA,OPTIONS)
%   [U,S,V] = LANSVD('Afun','Atransfun',M,N,K,SIGMA,OPTIONS)
%
%   where K is the number of singular values desired and
%   SIGMA is 'L' or 'S'.
%
%   The OPTIONS structure specifies certain parameters in the algorithm.
%    Field name      Parameter                              Default
%
%    OPTIONS.tol     Convergence tolerance                  16*eps
%    OPTIONS.lanmax  Dimension of the Lanczos basis.
%    OPTIONS.p0      Starting vector for the Lanczos        rand(n,1)-0.5
%                    iteration.
%    OPTIONS.delta   Level of orthogonality among the       sqrt(eps/K)
%                    Lanczos vectors.
%    OPTIONS.eta     Level of orthogonality after           10*eps^(3/4)
%                    reorthogonalization.
%    OPTIONS.cgs     reorthogonalization method used        0
%                    '0' : iterated modified Gram-Schmidt
%                    '1' : iterated classical Gram-Schmidt
%    OPTIONS.elr     If equal to 1 then extended local      1
%                    reorthogonalization is enforced.
%
%   See also LANBPRO, SVDS, SVD

% References:
% R.M. Larsen, Ph.D. Thesis, Aarhus University, 1998.
%
% B. N. Parlett, ``The Symmetric Eigenvalue Problem'',
% Prentice-Hall, Englewood Cliffs, NJ, 1980.
%
% H. D. Simon, ``The Lanczos algorithm with partial reorthogonalization'',
% Math. Comp. 42 (1984), no. 165, 115--142.

% Rasmus Munk Larsen, DAIMI, 1998

% Modifications: Stephen Becker, srbecker@caltech.edu, 2008, 2009


%%%%%%%%%%%%%%%%%%%%% Parse and check input arguments. %%%%%%%%%%%%%%%%%%%%%%

A = varargin{1};
%     if ~isreal(A)
%         error('A must be real')
%     end
[m n] = size(A);
if length(varargin) < 2, k=min(min(m,n),6); else  k=varargin{2}; end
if length(varargin) < 3, sigma = 'L';       else  sigma=varargin{3}; end
if length(varargin) < 4, options = [];      else  options=varargin{4}; end

if ~isnumeric(n) || real(abs(fix(n))) ~= n || ~isnumeric(m) || ...
        real(abs(fix(m))) ~= m || ~isnumeric(k) || real(abs(fix(k))) ~= k
    error('M, N and K must be positive integers.')
end


% Quick return for min(m,n) equal to 0 or 1 or for zero A.
if min(n,m) < 1 || k<1
    if nargout<3
        U = zeros(k,1);
    else
        U = eye(m,k); S = zeros(k,k);  V = eye(n,k);  bnd = zeros(k,1);
    end
    return
elseif min(n,m) == 1 && k>0
    if nargout==1
        U = norm(A);
    else
        [U,S,V] = svd(full(A));
        bnd = 0;
    end
    return
end

% A is the matrix of all zeros (not detectable if A is defined by an m-file)
if  nnz(A)==0
	if nargout<3
		U = zeros(k,1);
	else
		U = eye(m,k); S = zeros(k,k);  V = eye(n,k);  bnd = zeros(k,1);
	end
	return
end

lanmax = min(m,n);
tol = 16*eps;
p = rand(m,1)-0.5;
% Parse options struct
if isstruct(options)
    c = fieldnames(options);
    for i=1:length(c)  % SRB changing strcmp to strcmpi
        if any(strcmpi(c(i),'p0')), p = getfield(options,'p0'); p=p(:); end
        if any(strcmpi(c(i),'tol')), tol = getfield(options,'tol'); end
        if any(strcmpi(c(i),'lanmax')), lanmax = getfield(options,'lanmax'); end
    end
end

% Protect against absurd options.
tol = max(tol,eps);
lanmax = min(lanmax,min(m,n));
if size(p,1)~=m
    error('p0 must be a vector of length m')
end

lanmax = min(lanmax,min(m,n));
if k>lanmax
    error('K must satisfy  K <= LANMAX <= MIN(M,N).');
end

%%%%%%%%%%%%%%%%%%%%% Here begins the computation  %%%%%%%%%%%%%%%%%%%%%%

ksave = k;
neig = 0; nrestart=-1;
j = min(k+max(8,k)+1,lanmax);
U = []; V = []; B = []; anorm = []; work = zeros(2,2);

while neig < k
    
    %%%%%%%%%%%%%%%%%%%%% Compute Lanczos bidiagonalization %%%%%%%%%%%%%%%%%
    [U,B,V,p,ierr,w] = lanbpro_modified_nocomplex(A,j,p,options,U,B,V,anorm);
    work= work + w;
    
    if ierr<0 % Invariant subspace of dimension -ierr found.
        j = -ierr;
    end
    
    %%%%%%%%%%%%%%%%%% Compute singular values and error bounds %%%%%%%%%%%%%%%%
    % Analyze B
    resnrm = norm(p);

	if length(B) == 1
        S = B; bot = 1;
    else
        [S,bot] = bdsqr_modified_mex(diag(B),[diag(B,-1); resnrm]);
    end
    
    % Use Largest Ritz value to estimate ||A||_2. This might save some
    % reorth. in case of restart.
    anorm=S(1);
    
    % Set simple error bounds
    bnd = resnrm*abs(bot);
    
    % Examine gap structure and refine error bounds
    bnd = refinebounds(S.^2,bnd,n*eps*anorm);
    
    %%%%%%%%%%%%%%%%%%% Check convergence criterion %%%%%%%%%%%%%%%%%%%%
    i=1;
    neig = 0;
    while i<=min(j,k)
        if (bnd(i) <= tol*abs(S(i)))
            neig = neig + 1;
            i = i+1;
        else
            i = min(j,k)+1;
        end
    end
    
    %%%%%%%%%% Check whether to stop or to extend the Krylov basis? %%%%%%%%%%
    if ierr<0 % Invariant subspace found
        if j<k
            warning(['Invariant subspace of dimension ',num2str(j-1),' found.'])
        end
        j = j-1;
        break;
    end
    if j>=lanmax % Maximal dimension of Krylov subspace reached. Bail out
        if j>=min(m,n)
            neig = ksave;
            break;
        end
        if neig<ksave
            warning(['Maximum dimension of Krylov subspace exceeded prior',...
                ' to convergence.']);
        end
        break;
    end
    
    % Increase dimension of Krylov subspace
    if neig>0
        % increase j by approx. half the average number of steps pr. converged
        % singular value (j/neig) times the number of remaining ones (k-neig).
        j = j + min(100,max(2,0.5*(k-neig)*j/(neig+1)));
    else
        % As long a very few singular values have converged, increase j rapidly.
        %    j = j + ceil(min(100,max(8,2^nrestart*k)));
        j = max(1.5*j,j+10);
    end
    j = ceil(min(j+1,lanmax));
    nrestart = nrestart + 1;
end



%%%%%%%%%%%%%%%% Lanczos converged (or failed). Prepare output %%%%%%%%%%%%%%%
k = min(ksave,j);

if nargout>2
    j = size(B,2);
    % Compute singular vectors
    [P,S,Q] = svd(full([B;[zeros(1,j-1),resnrm]]),0);
    S = diag(S);
    if size(Q,2)~=k
        Q = Q(:,1:k);
        P = P(:,1:k);
    end
    % Compute and normalize Ritz vectors (overwrites U and V to save memory).
    if resnrm~=0
        U = U*P(1:j,:) + (p/resnrm)*P(j+1,:);
    else
        U = U*P(1:j,:);
    end
    V = V*Q;
    for i=1:k
        nq = norm(V(:,i));
        if isfinite(nq) && nq~=0 && nq~=1
            V(:,i) = V(:,i)/nq;
        end
        nq = norm(U(:,i));
        if isfinite(nq) && nq~=0 && nq~=1
            U(:,i) = U(:,i)/nq;
        end
    end
end

% Pick out desired part the spectrum
S = S(1:k);
bnd = bnd(1:k);

% if strcmp(sigma,'S')
%     [S,p] = sort(-1./S);
%     S = -S;
%     bnd = bnd(p);
%     if nargout>2
%         if issparse(A.A)
%             U = A.A*(A.R\U(:,p));
%             V(pmmd,:) = V(:,p);
%         else
%             U = A.Q(:,1:min(m,n))*U(:,p);
%             V = V(:,p);
%         end
%     end
% end

if nargout<3
    U = S;
    S = B; % Undocumented feature -  for checking B.
else
    S = diag(S);
end
