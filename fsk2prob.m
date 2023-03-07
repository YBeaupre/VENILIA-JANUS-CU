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
%| Authors: Sandipa Singh, Lee Freitag                                    |
%+------------------------------------------------------------------------+
%
% FSK2PROB Convert FSK filter back outputs into a probability metric.
%
% Inputs:
%   r       Two column matrix of FSK filter bank outputs.
%
% Outputs:
%   prob    Probability metric in the range of 0 < p < 1.
%

function prob = fsk2prob(r)
    sumr = (sum(r.')).';
    a1 = r(:, 1) ./ sumr;
    b1 = r(:, 2) ./ sumr;
    
    % i.e. a' + b' = 1
    prob = ((b1 - a1) + 1) / 2;
    % so that 0 < prob < 1
end
