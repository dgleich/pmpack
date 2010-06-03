function problems_tests

addpath('../problems');
try
    %% elliptic1d
	P = elliptic1d('epsilon',0.01); errs = zeros(19,1);
    for n=2:20 % try pseudospectral with 2 to 10 basis functions
      X = pseudospectral(P.solve,P.s,n);
      errs(n-1) = P.N*residual_error_estimate(X,P.Av,P.b)/norm(P.b(0));
    end
    semilogy(2:20,errs,'.-');
    
    %% twobytwo
    P = twobytwo(0.01); % a harder problem
    X = pseudospectral(P.solve,P.s,10);
    residual_error_estimate(X,P.Av,P.b)
    % eek, bad accuracy, use 100 points!
    X = pseudospectral(P.solve,P.s,100);
    residual_error_estimate(X,P.Av,P.b)
    
    %% ellipticnd
    P = ellipticnd;
    dt=tic; X1 = pseudospectral(P.solve,P.s,1); toc(dt);
    dt=tic; X1 = pseudospectral(P.solve,P.s,2); toc(dt); % a lot longer!
    
catch me
    rmpath('../problems');
    throw(me);
end
rmpath('../problems');
