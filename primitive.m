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
%| Authors: Dale Green, Giovanni Zappa.                                   |
%+------------------------------------------------------------------------+
%
% PRIMITIVE A routine to find a prime number of blocks to fit within
% a prescribed bandwidth, and a primitive element for that number.
%
function [qsize, alpha] = primitive(nblock)
    qsize = nblock + 1;
    oprime = 0;
    while oprime == 0,	%search for a prime number nearest to the desired # blocks
        Qmax2 = round(qsize / 2);
        for k = 2 : round(qsize / 2);
            oprime = 1;
            dum = rem(qsize, k);
            if(dum == 0),
                qsize = qsize - 1;
                oprime = 0;
                break;
            end
            if(k == Qmax2),	%went all the way without finding a prime factor
                oprime = 1;
            end
        end
    end
    
    ofind = 1;
    if(ofind == 1),
        powers=(1 : 1 : (qsize - 1));
        alpha = 1;
        done = 0;
        while done == 0 && alpha < qsize,  %see LIN, page 24, example
            x = zeros(1, qsize - 1);
            alpha = alpha + 1;
            x(1) = alpha;
            for k = 2 : qsize - 1,
                x(k) = rem(x(k - 1) * alpha, qsize);
            end
            x = sort(x);
            if((diff(x)) == ones(1, qsize - 2)),
                done = 1;
            end
        end
        if (alpha == qsize),
            error('janus:primitive:unk', 'failed to find primitive element');
        end
    end
end
