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
% DEMOD Demodulate a JANUS signal.
%
% Inputs:
%    pset       Parameter set object.
%    bband      Complex baseband signal.
%    slots      Frequency hopping pattern, generated by HOP_PATTERN.
%    nbits      Number of bits to demodulate.
%    cfactor    fixme
%
% Outputs:
%    data       Sequence of decoded bytes.
%    dec_bits   Sequence of decoded bits.
%    dlv_seq    Sequence of bytes used as input for the decoder.
%    bit_prob   Sequence of probability metrics in the range of 0 < p < 1.
%

function [data, dec_bits, dlv_seq, bit_prob] = demod(pset, bband, bband_fs, slots, nbits, cfactor)
    
    global verbose;

    defaults;
    
    if (nargin < 6)
        cfactor = 1;
    end
    
    bband_ts = 1 / bband_fs;
    
    % Correct hopping edges for range rate.
    fh = (fix(CHIP_NFRQ / 2) * ALPHABET_SIZE  + 1) * pset.chip_frq ;
    fkeep = -fh + (0 : pset.prim_q * 2 - 1) * pset.chip_frq;
    fkeep = (pset.cfreq + fkeep) * cfactor - pset.cfreq;

    % Time correlation (no FFT), generating bank of frequencies.
    factor = (2 - cfactor) * pset.chip_dur * bband_fs;  
    t = 0 : bband_ts : ceil(factor - 1) * bband_ts;
    tw = tukeywin(length(t), 0.05);
    st = tw * ones(size(fkeep)) .* exp(-i * 2 * pi * fkeep' * t) .';

    % Prepare demodulation statistics (power).
    nchip = 2 * (nbits + CONV_ENC_MEM);    
    stats = zeros(ALPHABET_SIZE, nchip);
    
    % Compute statistics.
    grab1 = 1;
    count = 1;
    for kk = 1 : nchip,
        lchip = round(kk * factor) - round((kk - 1) * factor);
        grab2 = grab1 + lchip - 1;
        slots_idx = slots(kk) * 2;
        w = st(1 : lchip, [slots_idx + 1 slots_idx + 2]);
        stats(:, count) = (abs(bband(grab1 : grab2) .' * w) / lchip) .^ 2;

        if (verbose && ~mod(kk, 8))
            figure(10);
            fft_len = lchip;
            FRSignal = abs(fftshift(fft(bband(grab1 : grab2), fft_len))) / fft_len;
            xlFt = floor((fft_len * pset.bwidth / bband_fs ) * [-1 1]) + ceil(fft_len / 2);
            stem((ceil(-fft_len / 2):floor((fft_len - .5) / 2)) * bband_fs  / fft_len,  ...
                [ abs(fftshift(fft(conj(st(1 : lchip, slots(kk) * 2 + (1:2))), fft_len))) * ...
                max(FRSignal(xlFt(1) : xlFt(2))) / fft_len  FRSignal ]);
        end

        count = count + 1;
        grab1 = grab2 + 1;
    end

    % Deinterleave.
    q = interleaver_prime(nchip);
    bit_prob = fsk2prob(stats');
    bits = floor(bit_prob * 256);
    dlv_seq = deinterleave(bits', q)';
    
    % Decode.
    trellis = poly2trellis(CONV_ENC_CLEN, CONV_ENC_CGEN);
    dec_bits = vitdec(dlv_seq, trellis, min(9 * 5, length(dlv_seq) / 2), 'trunc', 'soft', 8);
    dec_bits = dec_bits(1 : nbits);
    
    % Convert back to bytes.
    data = reshape(dec_bits, 8, length(dec_bits) / 8);
    data = uint8(([128 64 32 16 8 4 2 1] * data));
end
