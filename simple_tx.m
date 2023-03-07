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
%| Author: Ricardo Martins   
%  Edited: Michel Barbeau, Carleton University (July 20, 2022)
%+------------------------------------------------------------------------+
%
% SIMPLE_TX Simplified interface to generate a JANUS waveform.
%
% Inputs:
%    pset_file  Parameter set file (CSV).
%    pset_id    Parameter set Id.
%    varargin   Optional parameters.
%
% Outputs:
%    pkt        Encoded packet.
%    state      Structure with info from the encoder
%    params     Parameters used to generate the signal
%    signal     Broadband signal
%
% See also TX, PARAMETERS.
%

function [pkt, state, params, signal] = simple_tx(pset_file, pset_id, varargin)
    defaults;

    if (nargin < 2)
        error('This function requires at least 2 arguments.');
    end

    % Retrieve optional arguments.
    params = parameters(struct(varargin{:}));

    % Load parameter set configuration.
    pset = pset_load(pset_file, pset_id, params);

    % Choose the minimum suitable sampling frequency
    % if none is given.
    min_fs = pset.bwidth * 1.1;
    if (params.stream_passband)
        min_fs = min_fs + pset.cfreq * 2.2;
    end
    if (params.stream_fs == 0)
        fs_idx = find(COMMON_FS >= min_fs, 1, 'first');
        params.stream_fs = COMMON_FS(fs_idx);
    end

    if (params.stream_fs < min_fs)
        error('sampling frequency is too low');
    end

    % Generate baseband signal.
    [bband, pkt, state] = tx(pset, params.stream_fs, params);

    % Pad signal if needed.
    if (params.stream_mul)
        l = length(bband);
        m = rem(l, params.stream_mul);
        if (m ~= 0)
            pad = zeros(params.stream_mul - m, 1);
            bband = [bband; pad];
        end
    end

    % Convert to passband if needed.
    if (params.stream_passband)
        % Extract frequency of carrier
        fs = params.stream_fs;
        t = 0 : 1 / fs : (length(bband) - 1) / fs;
        % Exponential modulation
        signal = real(bband .* exp(i * 2 * pi * pset.cfreq .* t'));
    else
        signal = [real(bband) imag(bband)];
    end

    % Apply amplitude factor.
    signal = signal * params.stream_amp;

    % If multichannel
    if (params.stream_channels > 1)
        signalc = signal;
        signal = zeros(length(signalc), params.stream_channels);
        signal(:, params.stream_channel + 1) = signalc;
        clear signalc;
    end
    
    % Write output.
    switch (params.stream_driver)
      case 'null'
        % do nothing.
      case 'mem'
        eval(['global ' params.stream_driver_args ]);
        eval([params.stream_driver_args ' = signal;' ]);
        disp(['Remember to have: global ' params.stream_driver_args ])
      case 'wav'
        audiowrite(params.stream_driver_args, signal, params.stream_fs, 'BitsPerSample', params.stream_bps);
      case 'mat'
        save(params.stream_driver_args, 'signal', 'params');
      otherwise
        error('unsupported stream type');
    end
end
