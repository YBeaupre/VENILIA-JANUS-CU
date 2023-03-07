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
% COMPUTE_DOPPLER estimate gamma dialation factor (c+v)/c and speed (v) for a chip sequence.
%
% Inputs:
%    preamble          Baseband waveform containg the preamble.
%    chip_dur          Chip duration [s].
%    chip_frq          Chip frequency separation [Hz].
%    freq_list         List of baseband frequency sequence of chips.
%    bband_fs          Baseband sampling frequency [Hz].
%    cfreq             Central frequency of the pass-band signal [Hz].
%    max_speed         Max Doppler speed [m/s]. Default 5.
%    nchip             Number of chips to process. Default 32.
%
% Outputs:
%    gamma             Doppler frequency dialation factor.
%    speed             Estimated Doppler speed [m/s].
%
% See also DETECTOR_PARAMETERS, CHIPS_ALIGNMENT, DETECT_FIRST, QUAD_FITN.

function [gamma, speed] = compute_doppler(preamble, chip_dur, chip_frq, freq_list, bband_fs, cfreq, max_speed, nchip)

    global verbose;
    
    c = 1540;

    if (nargin < 7)
        nchip = 32;           % default number of chips
        if (nargin < 6)
            max_speed = 5;    % default max speed
        end
    end 
    
    lacc = ceil(chip_dur * bband_fs * (nchip * c / (c - max_speed) - (nchip - 1) * c / (c + max_speed)));

    % Compute zero padding to have 9 points into the main lobe.
    int_npoint = 9;  % only odd numbers
    hf_npoint = fix(int_npoint/2);
    cpad = max(round((int_npoint + 3) * bband_fs * chip_dur / 2), lacc);

    res_freq = bband_fs / cpad;
    
    % Compute maximum Doppler shift at max_speed.
    fs_shift = ceil((cfreq + max(abs(freq_list)) + 2 / chip_dur) * max_speed / c / res_freq);
    
    fvalues = floor((-cpad + 1) / 2) / cpad * bband_fs : res_freq : floor((cpad - 1) / 2) / cpad * bband_fs;
    
    if (verbose)
        figure(3);
        plot((1 : length(preamble)) / bband_fs, real(preamble), 'b');
        hold on;
    end
    
    % Compute Doppler estimator quadratic interpolation.
    gammas = NaN * ones(1, nchip);  
    for count = 1 : nchip
        c_start = max(1, round(bband_fs * chip_dur * (count - 1) * c / (c + max_speed)));
        c_end = min(length(preamble), round(bband_fs * chip_dur * count * c / (c - max_speed)));

        fft_v = fft(preamble(c_start : c_end) .* hamming(c_end - c_start + 1) .', cpad);
        psd = abs(fftshift(fft_v)) .^ 2;

        % Compute the index of the tone.
        f_idx = round(freq_list(count) / res_freq) + fix(cpad / 2) + 1;

        % Compute the peak position.
        [p_peak f_peak_idx] = max(psd(f_idx - fs_shift - hf_npoint : f_idx + fs_shift + hf_npoint));
        f_peak_idx = f_peak_idx - fs_shift - hf_npoint - 1;

        % Computes the interpolation coefficients.
        [a b] = quad_fitN((fvalues(f_idx + f_peak_idx - hf_npoint : f_idx + f_peak_idx + hf_npoint)) - freq_list(count), ...
                            psd(f_idx + f_peak_idx - hf_npoint : f_idx + f_peak_idx + hf_npoint), int_npoint);
        if (a < 0)
            est_f_offset = -b / (2 * a);
            gamma_chip = 1 + est_f_offset / (freq_list(count) + cfreq);
            speed_chip = c - c .* gamma_chip;
            if (abs(speed_chip) < max_speed)
                % fprintf('chip = %02d, freq = %-03.1f, err = %-1.3f\n', count, fvalues(f_idx + f_peak_idx), est_f_offset);  %debuging info
                gammas(count) = gamma_chip;
            end
        end
        if (verbose)
            interpf = (fvalues(f_idx + f_peak_idx - hf_npoint) : res_freq / 10 : fvalues(f_idx + f_peak_idx + hf_npoint)) - freq_list(count);
            quadVal = a .* interpf .^ 2 + b .* interpf;
            c1 = quadVal(1) - psd(f_idx + f_peak_idx - hf_npoint);
            quadVal = quadVal - c1;
            figure(3);
            plot(c_start * [1 1] / bband_fs, [0 max(abs(preamble))], '-xk', c_end * [1 1] / bband_fs, [0 max(abs(preamble))], '-+y');
            figure(4);
            stem(freq_list, ones(size(freq_list)) * max(psd), 'k');
            hold on;
            plot(fvalues, zeros(size(fvalues)), '.m', ...
                 fvalues, psd, '-+b', ...
                 [1 1] * freq_list(count), [0 max(psd)], 'r', ...
                 fvalues(f_idx + f_peak_idx - hf_npoint : f_idx + f_peak_idx + hf_npoint), psd(f_idx + f_peak_idx - hf_npoint : f_idx + f_peak_idx + hf_npoint), 'xg', ...
                 interpf + freq_list(count), quadVal, 'g');
            hold off;

            xlim([min(freq_list) * 1.1 max(freq_list) * 1.1])
        end
    end
    
    if (verbose)
        figure(3);
        hold off
    end
    
    gamma = median(gammas(~isnan(gammas)));
    if (isnan(gamma))
        gamma = 1;
        speed = NaN;
    else
        speed = c - c .* gamma;	    
    end
end
