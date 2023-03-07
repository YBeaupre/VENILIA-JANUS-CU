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
% CHIPS_ALIGNMENT Compute inchorent sum of energy of preamble chips.
%
% Inputs:
%    bband             Complex baseband signal.
%    bband_fs          Baseband sampling frequency [Hz].
%    chip_dur          Chip duration [s].
%    chip_oversampling Chip oversampling factor.
%    freq_vec          Vector of used baseband frequencies in the preamble.
%    chip_order        Indexes order of preamble's frequencies.
%    max_speed         Max Doppler speed [m/s].
%
% Outputs:
%    chip_corr         Inchorent sum of energy of preamble chips.
%    align_delay       Delay from baseband signal and chip_corr [s].
%
% See also DETECTOR_PARAMETERS.

function [chip_corr, align_delay] = chips_alignment(bband, bband_fs, chip_dur, chip_oversampling, freq_vec, chip_order, max_speed)

n_chips = length(chip_order);

chip_s = fix(chip_dur * bband_fs);

gf_size = floor(bband_fs * (1540 * chip_dur) / ((chip_dur * max(freq_vec) + 1) * max_speed + 1540));

% forcing Goertzel window to be at least 3 / 4 of chip
gf_size = max(gf_size, fix(3 * chip_s / 4));

step_s = (chip_dur * bband_fs) / chip_oversampling;
[s] = goertzel_spectrum(bband, gf_size, gf_size - step_s, freq_vec, bband_fs);

rr = abs(s) ./ n_chips;

% maximum filter
r = zeros(size(rr, 1), size(rr, 2), 2);
r(:, 1 : end - 1, 2) = rr(:, 2 : end);
r(:, :, 1) = [ rr(:, :) ];
g = max(r, [], 3);

chip_corr_len = length(g) - 2 * chip_oversampling * (length(chip_order) - 1);
chip_corr = zeros(1, chip_corr_len);
for c = 1 : length(chip_order)
    chip_corr(c, :) = g(chip_order(c), chip_oversampling * (c - 1) + 1:chip_oversampling * (c - 1) + chip_corr_len);
end

align_delay = gf_size * (1 - 1 / chip_oversampling) / bband_fs / 2;

chip_corr = sum(chip_corr, 1);
