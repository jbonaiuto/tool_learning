
% `b` and `d` are Gamma shape parameters and
% `a` and `c` are scale parameters.
% (All, therefore, must be positive.)
%
function x=kl_gamma(a,b,c,d)
  x=((a-c)/c)*b + gammaln(d) - gammaln(b) + d*log(c) - b*log(a) + (b-d)*(log(a) + psi(b)) ;
end