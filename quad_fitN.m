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
%| Author: Giovanni Zappa                                                 |
%+------------------------------------------------------------------------+
%
% QUAD_FITN computes the a*x^2+b*x parameter of the LSE quadratic passing through N points.
%
% Inputs:
%    x         Vector value.
%    y         Vector value.
%    N         Number of vector points.
%
% Outputs:
%    a         Polynomial coefficient.
%    b         Polynomial coefficient.

function [a b] = quad_fitN(x, y, N)

np = length(x);

if (N ~= np)
    error(['the length of the vectors should be ' num2str(N)]);
end

if (N ~= length(y))
    error(['the length of the vectors should be ' num2str(N)]);
end

s1 = sum(x);
s2 = sum(x .^ 2);
s3 = sum(x .^ 3);
s4 = sum(x .^ 4);

sy = sum(y);
sxy = x * y .';
sx2y = (x .^ 2) * y .';

d = (N * s2 * s4 - s1^2 * s4 - N * s3^2 + 2 * s1 * s2 * s3 - s2^3);

a = (s1 * s3 * sy - s2^2 * sy - N * s3 * sxy + s1 * s2 * sxy + N * s2 * sx2y - s1^2 * sx2y) / d;

b = -(s1 * s4 * sy - s2 * s3 * sy - N * s4 * sxy + s2^2 * sxy + N * s3 * sx2y - s1 * s2 * sx2y) / d;

end
