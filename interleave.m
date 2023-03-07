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
%| Author: Dale Green                                                     |
%+------------------------------------------------------------------------+
%
% INTERLEAVE Block interleaver based on a prime number algorithm.
%
% Inputs:
%   data      Byte sequence.
%
% Outputs:
%   ileaved   Interleaved byte sequence.
%   prime     Prime number used.
%
% See also interleaver_prime, deinterleaver.
%

function [ileaved, prime] = interleave(data)
    data = data(:)';
    data_len = length(data);
    prime = interleaver_prime(data_len);
    y = zeros(1, data_len);  
    y(1) = 1;  
    for k = 2 : data_len
        y(k) = rem(y(k - 1) + prime - 1, data_len) + 1;
    end
    
    ileaved = data(:,y);
end
