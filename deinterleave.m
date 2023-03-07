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
%| Author: Unknown                                                        |
%+------------------------------------------------------------------------+
%
% DEINTERLEAVE Deinterleave a sequence interleaved by INTERLEAVE.
%
% Inputs:
%   ileaved  Interleaved sequence in the form (Mary, Nchips).
%   q        Prime number used to interleave the sequence.
%
% Outputs:
%   dleaved  Deinterleaved sequence.
%

function dleaved = deinterleave(ileaved, q);
    ileaved_len = length(ileaved);
    dleaved = zeros(size(ileaved));
    dleaved(:, 1) = ileaved(:, 1);
    idx = 1;
    for k = 2 : ileaved_len,
        idx = rem(idx + q - 1, ileaved_len) + 1;
        dleaved(:, idx) = ileaved(:, k);
    end
end
