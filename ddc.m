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
%| Authors: Dale Green, Giovanni Zappa, Ricardo Martins                   |
%+------------------------------------------------------------------------+
%
% DDC Digital down-converter.
%
% Convert and down-sample a digitized real signal to a basebanded
% complex signal.
%
% Inputs:
%    pband     Passband signal.
%    bband_fs  Passband sampling frequency (Hz).
%    cfreq     Passband center frequency (Hz).
%    bwidth    Baseband bandwidth (Hz).
%
% Outputs:
%    bband     Complex baseband signal.
%    bband_fs  Sampling frequency of baseband signal (Hz).
%

function [bband, bband_fs] = ddc(pband, pband_fs, cfreq, bwidth, params)
    if (nargin < 5)
        params = parameters();
    end

    % Compute ratio and make it a power of two. The ratio allows 40%
    % more bandwidth than the nyquist frequency.
    bwidth = bwidth * 1.40;
    ratio = floor(pband_fs / (2 * bwidth));
    if (ratio == 0)
        error('sampling frequency is too low');
    end
    ratio = bitshift(1, fix(log2(ratio)));
    bband_fs = pband_fs / ratio;
    
    pband = pband(:);
    M = length(pband);
    N = min(M, 2048);
    off = fix(cfreq / ratio);
    f1 = cfreq - off;
    dt = 1 / pband_fs;
    t = 0 : dt : (N - 1) * dt;
    e = exp(-i * 2 * pi * f1 * t);
    e = e(:);
    bband = zeros(fix(length(pband) / ratio), 1);
    b = fir1(255, bwidth / pband_fs);
    if (size(b, 1) ~= 1)
        b = b';
    end
    b = b .* exp(i * 2 * pi * off * [0 : (length(b) - 1)] * dt);
    b = b(:);
    B = fft(b, N);
    posit = N / (2 * ratio);
    count = ceil(M / (N / 2));
    phase1 = exp(-i * 2 * pi * N / 2 * f1 * dt);
    
    for k = 1 : count,
        p1 = (k - 1) * N / 2;
        phase = exp(-i * 2 * pi * p1 * f1 * dt);
        p2 = p1 + N;
        p2 = min(p2, M);
        a = pband(p1 + 1 : p2);
        a = [a; zeros(N - (p2 - p1), 1)];
        dum = a .* e * phase;
        D = fft(dum, N);
        d = ifft(D .* B);
        d = reshape(d(N / 2 + 1 : N), ratio, N / 2 / ratio);
        d = d(1,:);
        bband((k - 1) * posit + 1 : k * posit) = d;
    end
    
    bband = bband(1 : fix(length(pband) / ratio)) * phase1;
    dt = dt * ratio;
    t = 0 : dt : (length(bband) - 1) * dt;
    e = exp(-i*2*pi*off*t);
    e = e(:);
    bband = -bband .* e; % Can't explain this minus sign.
end
