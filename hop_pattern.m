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
%| Authors: Giovanni Zappa, Dale Green                                    |
%+------------------------------------------------------------------------+
%
% HOP_PATTERN Generate the hopping frequency indices.
%
% This routine provides the hopping frequency indices using Galois
% Field arithmetic with the primitive element alpha.
%
% Inputs:
%   alpha      Primitive element.
%   block_len  Number of blocks within the available bandwidth.
%   m          Number of hops required.
%
% Outputs:
%   slots      Array with the hopping frequency indices.
%
% References:
%   - Mersereau & Seay, "Multiple Access Frequency Hopping Patterns with
%     Low Ambiguity", IEEE Trans Aerospace & Elec. Sys, Vol AES-17, No.4,
%     July 1981
%

function slots = hop_pattern(alpha, block_len, m)
    % k is the allowed maximum number of hits between patterns.
    k = 3;
    mu = zeros(m, k);
    mu(:, k - 1) = ceil((1 : m) / ((block_len - 1) * block_len));
    mu(:, k) = floor((0 : m - 1)' ./ (block_len - 1));
    mghat = mod_pow(alpha, ((0 : k - 1)' * (rem(0 : m - 1, block_len - 1) + 1))', block_len);
    slots = rem(mu .* mghat * ones(1, k)', block_len);
end
