%+------------------------------------------------------------------------+
%| JANUS is a simple, robust, open standard signalling method for         |
%| underwater communications. See <http://www.januswiki.org> for details. |
%+------------------------------------------------------------------------+
%| Example software implementations provided by STO CMRE are subject to   |
%| Copyright (C) 2008-2018 STO Centre for Maritime Research and           |
%| Experimentation (CMRE)                                                 |
%|                                                                        |
%| This is free software: you can redistribute it and/or modify it        |
%| under the terms of the GNU General Public License version 3 as         |
%| published by the Free Software Foundation.                             |
%|                                                                        |
%| This program is distributed in the hope that it will be useful, but    |
%| WITHOUT ANY WARRANTY; without even the implied warranty of FITNESS     |
%| FOR A PARTICULAR PURPOSE. See the GNU General Public License for       |
%| more details.                                                          |
%|                                                                        |
%| You should have received a copy of the GNU General Public License      |
%| along with this program. If not, see <http://www.gnu.org/licenses/>.   |
%+------------------------------------------------------------------------+
%| Author: Giovanni Zappa.                                                |
%+------------------------------------------------------------------------+
%
% MOD_POW Compute modular exponentiation: b^e (mod n).
%
% Inputs:
%   b          Base.
%   e          Exponent (vector or matrix).
%   m          Modulus.
%
% Outputs:
%   p          b^e (mod n).
%
% References:
%   - http://en.wikipedia.org/wiki/Modular_exponentiation
%

function p = mod_pow(b, e, n),
    p = ones(size(e));
    temp = b;
    while max(e(:)) > 0
        [in] = find(mod(e(:), 2) == 1);
        p(in) = mod(p(in) * temp, n);
        temp = mod(temp .^ 2, n);
        e = floor(e / 2);
    end
end
