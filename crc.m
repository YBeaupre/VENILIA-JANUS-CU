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
%| Author: Ricardo Martins                                                |
%+------------------------------------------------------------------------+
%
% CRC Compute the CRC8 of a byte sequence.
% 
% Inputs:
%   data  Byte sequence.
%   poly  Polynomial.
%   crc   Initial CRC (0 if not given).
%
%  Outputs:
%   crc   CRC8 of input byte sequence.
%

function c = crc(data, poly, c)
    if (nargin < 3)
        c = 0;
    end
    
    for i = 1 : length(data)
        c = bitxor(c, data(i));
        for j = 0 : 7
            if (bitand(c, 128))
                c = bitshift(c, 1);
                c = bitxor(c, poly);
            else
                c = bitshift(c, 1);
            end
        end
        
        c = bitand(c, 255);
    end
end
