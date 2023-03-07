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
% WAKE_UP_TONES Generate three wake-up tones.
%
% Inputs:
%    ts      Sampling period (s).
%    nsample Number of samples.
%    bwidth  Bandwidth (Hz).
%
% Outputs:
%    bband   Complex baseband signal.
%

function bband = wake_up_tones(ts, nsample, bwidth)
    tcw = (0 : ts : (nsample - 1) * ts)';
    lcw = length(tcw);
    cw_win = tukeywin(lcw, 0.05);
    bband = zeros(lcw * 3, 1);
    bband(1 : lcw) = cw_win .* exp(i * (2 * pi * (-bwidth / 2) .* tcw + pi / 2));
    bband(1 * lcw + 1 : 2 * lcw) = cw_win * i;
    bband(2 * lcw + 1 : 3 * lcw) = cw_win .* exp(i * (2 * pi * (bwidth / 2) .* tcw + pi / 2));
end
