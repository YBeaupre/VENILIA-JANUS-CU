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
% DETECT_FIRST detects the first transmission.
%
% Inputs:
%    chip_corr         Inchorent sum of energy of preamble chips.
%    threshold         Detector GO-CFAR threshold.
%    step_l            Number of quarter of chips used for the mooving average.
%    chip_oversampling Chips oversampling factor.
%    guard_time        Number of quarter of chips used for the guard time of CFAR.
%
% Outputs:
%    offs_detector     Start of detected signal in the oversampled domain.
%
% See also DETECTOR_PARAMETERS, CHIPS_ALIGNMENT.

function [offs_detector] = detect_first(chip_corr, threshold, step_l, chip_oversampling, guard_time)

global verbose;
%global mcp mm mv mvd mmd;

hw_size = step_l + guard_time;
pad_size = hw_size;
chip_corr_padded = [zeros(1, pad_size) chip_corr zeros(1, pad_size)];

% Cell filter.
step = ones(1, step_l) / step_l;
flen = step_l + length(chip_corr_padded) - 1;

mov_avgF = zeros(1, flen);
mov_avgF(:) = fft(chip_corr_padded, flen) .* fft(step, flen);

% abs remove eventual negative values due to the an overshot.
mov_avg = abs(real(ifft(mov_avgF)));

d_istart = hw_size +  1;
d_istop = length(chip_corr) + pad_size;

r_window_correction = 0.145 * min((32 + 144) / round(step_l / chip_oversampling), 1);

detector = chip_corr_padded(d_istart : d_istop) > threshold * max(...  % GO-CFAR
           mov_avg((d_istart : d_istop) - guard_time), ...  % cell before
           mov_avg((d_istart : d_istop) + hw_size) - ... % following cell
           chip_corr_padded(d_istart : d_istop) * r_window_correction); % autocorr correction

detector = [zeros(1, d_istart - 1) detector];

chip_corr1 = chip_corr_padded;
chip_corr1(detector == 0) = 0;  % only where detector is true

detector = [detector(1 : end - 1), 0] - [0, detector(1 : end - 1)]; % numeric derivative
[detect_int_start_v, detect_int_start_h] = find(detector == 1); % detection intervals begin

% Look for the maximum in twice the preamble length from the first detection.
offs_detector = [];
if (~ isempty(detect_int_start_v))
    [ vm, imc ] = max(chip_corr1(detect_int_start_h(1) : detect_int_start_h(1) + 2 * 32 * chip_oversampling));
    %[ rb, imp ] = min(imc + detect_int_start_h(1) - 1 - ...
    %                  detect_int_start_h(detect_int_start_h - detect_int_start_h(1) < imc ));
    offs_detector = detect_int_start_h(1) + (imc - 1);

    offs_detector_r = offs_detector + findstep(chip_corr_padded(offs_detector - chip_oversampling : offs_detector));
    
    if (verbose)
        %mcp = chip_corr_padded(offs_detector);
        mcp = interp1((1:size(chip_corr_padded, 2)), chip_corr_padded, offs_detector_r);

        % To compare with theory.
        %offs_detector = fix(offs_detector_r);
        %mm = mean(mov_avg(offs_detector - hw_size : offs_detector - guard_time)) / mcp;
        %mv = var(mov_avg(offs_detector - hw_size : offs_detector - guard_time)) / mcp;
        %mvd = var(mov_avg(offs_detector + guard_time : offs_detector + hw_size)) / mcp;
        %mmd = mean(mov_avg(offs_detector + guard_time : offs_detector + hw_size)) / mcp;

        figure(6);
        win_bounds = [-hw_size -guard_time guard_time hw_size];
        %plot((1 : length(chip_corr_padded)) - pad_size, chip_corr_padded, 'b', ...
        %     (1 : length(mov_avg)) - pad_size, mov_avg, 'r', ...
        %     offs_detector_r + win_bounds - pad_size, chip_corr_padded(offs_detector + win_bounds), 'ok', ...
        %     [offs_detector_r - pad_size], mcp, 'or');
        plot((1 : length(chip_corr_padded)) - pad_size, chip_corr_padded, 'b', ...
             (1 : length(mov_avg)) - pad_size, mov_avg, 'r', ...
             offs_detector_r + win_bounds - pad_size, interp1((1:size(chip_corr_padded, 2)), chip_corr_padded, offs_detector_r + win_bounds), 'ok', ...
             [offs_detector_r - pad_size], mcp, 'or');
    end

    offs_detector = offs_detector_r - pad_size;
end

% FINDSTEP find the offset of step function in the data
%
% Inputs:
%    x              Sequence hiding a step function.
%
% Outputs:
%    r              Delay of the step function compared to a centred in the middle.

function [r] = findstep(x)

mx = max(x);

r = 1 - sum(x) / mx;
