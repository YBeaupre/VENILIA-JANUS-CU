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
% DEC2BINVEC Convert decimal number to a binary vector.
%    DEC2BINVEC(D) returns the binary representation of D as a binary
%    vector. The least significant bit is represented by the first 
%    column. D must be a non-negative integer. 
% 
%    DEC2BINVEC(D, N) produces a binary representation with at least
%    N bits.
% 
%    Example:
%       dec2binvec(23) returns [1 1 1 0 1]
%
%    See also DEC2BIN.
%

function out = dec2binvec(dec, n)
    if (nargin < 1)
        error('janus:dec2binvec:argcheck', 'DEC must be defined.')
    end
    
    if (~isa(dec, 'double'))
        error('janus:dec2binvec:argcheck', 'DEC must be a double.');
    end
    
    if (dec < 0)
        error('janus:dec2binvec:argcheck', 'DEC must be a positive integer.');
    end
    
    switch (nargin)
      case 1
        out = dec2bin(dec);
      case 2
        out = dec2bin(dec, n);
    end
    
    % Convert the binary string, '1011', to a binvec, [1 1 0 1].
    out = logical(str2num([fliplr(out); blanks(length(out))]')');
end
