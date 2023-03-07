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
%| Authors: Giovanni Zappa, Luigi Elia D'Amaro                            |
%+------------------------------------------------------------------------+
%
% GOERTZEL_SPECTRUM calculate the Spectrogram using a Short-Time Fourier
% Transform (STFT) of a signal using the Goertzel algorithm, similar to 
% the Matlab function spectrogram.
%
% Inputs:
%    x                 The input signal.
%    window            x is divided into segments of length window and
%                      a Hamming window of equal length is used.        
%    noverlap          The length of each segment of x overlaps.
%    freqvec           Vector corresponds to the frequency points at
%                      which the DFTis calculated using goertzel.
%    fs                Sampling frequency.
%
% Outputs:
%    s                 The DFT using the Goertzel algorithm.
%
% See also DETECTOR_PARAMETERS, CHIPS_ALIGNMENT.

function [s] = goertzel_spectrum(x, window, noverlap, freqvec, fs)
% [1] Oppenheim, A.V., and R.W. Schafer, Discrete-Time Signal Processing,
% Prentice-Hall, Englewood Cliffs, NJ, 1989, pp. 713-718.
% [2] Mitra, S. K., Digital Signal Processing. A Computer-Based Approach.
% 2nd Ed. McGraw-Hill, N.Y., 2001.

% [x,nx,xisreal,y,Ly,win,winName,winParam,noverlap,k,L,options,msg]

nx = length(x);

win = hamming(window);

% Determine the number of columns of the STFT output (i.e., the S output)
ncol = fix((nx - noverlap) / (window - noverlap));
 
L = floor(noverlap);

colindex = 1 + (0 : (ncol - 1)) * (window - noverlap);

rowindex = (1 : window)';

xin = zeros(window, ncol);

% Put x into columns of xin with the proper offset
xin(:) = x(rowindex(:, ones(1, ncol)) + fix(colindex(ones(window, 1), :)) - 1);

% Apply the window to the array of offset signal segments.
xin = win(:, ones(1, ncol)) .* xin;

f = mod(freqvec(:), fs); % 0 <= f < = Fs

xm = size(xin, 1); % NFFT

% Indices used by the Goertzel function (see equation 11.1 pg. 755 of [2])
fscaled = f / fs * xm + 1;
k = round(fscaled);

% shift for each frequency from default xm length grid
deltak = fscaled - k;

tempk = k;
% If k > xm, fold over to the 1st bin
k(tempk > xm) = 1;

n = (0 : xm - 1)';
s = zeros(size(k, 1), size(xin, 2));
for kindex = 1 : length(k)
    % We need to evaluate the DFT at the requested frequency instead of a
    % neighboring frequency that lies on the grid obtained with xm number
    % of points in the 0 to fs range. We do that by giving a complex phase
    % to xin equal to the offset from the frequency to its nearest neighbor
    % on the grid. This phase translates into a shift in the DFT by the
    % same amount. The s(k) then is the DFT at (k+deltak).
    
    % apply kernal to xin so as to evaluate DFT at k+deltak)
    kernel = exp(-j * 2 * pi * deltak(kindex) / xm * n);
    xin_phaseshifted = xin .* repmat(kernel, 1, size(xin, 2));
    
    s(kindex, :) = goertzel(xin_phaseshifted, k(kindex));
end

