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
%| Authors: Ricardo Martins, Giovanni Zappa, Luigi Elia D'Amaro           |
%+------------------------------------------------------------------------+
%
% SIMPLE_RX Simplified interface to decode a JANUS waveform.
%
% Inputs:
%    pset_file  Parameter set file (CSV).
%    pset_id    Parameter set Id.
%    varargin   Optional parameters.
%
% Outputs:
%    pkt        Decoded packet.
%    state      Structure with info from the decoder.
%    
% See also RX, TX, SIMPLE_TX, PARAMETERS.
%

function [pkt, state] = simple_rx(pset_file, pset_id, varargin)
    if (nargin < 2)
        error('This function requires at least 2 arguments.');
    end

    bband = [];
    pband = [];
    
    % Retrieve optional parameters.
    params = parameters(struct(varargin{:}));
    
    % Load parameter set configuration.
    pset = pset_load(pset_file, pset_id, params);

    % Read input.
    switch (params.stream_driver)
      case 'mem'
        eval(['global ' params.stream_driver_args ]);
        if (params.stream_passband)
            eval([ 'pband = ' params.stream_driver_args ';' ]);
            pband_fs = params.stream_fs;
        else
            eval([ 'bband = ' params.stream_driver_args ';' ]);
            bband_fs = params.stream_fs;
        end
        
      case 'wav'
        if (params.stream_passband)
            [pband, pband_fs] = audioread(params.stream_driver_args);
        else
            [bband, bband_fs] = audioread(params.stream_driver_args);
        end
        
      case 'mat'
        mat = load(params.stream_driver_args);
        params.stream_passband = mat.params.stream_passband;
        if (params.stream_passband)
            pband = mat.signal;
            pband_fs = mat.params.stream_fs;
        else
            bband = mat.signal;
            bband_fs = mat.params.stream_fs;
        end
        
      otherwise
        error('janus:simple_rx:inv_stream', 'unsupported stream type');
    end
    
    if (params.stream_passband)
        params.stream_fs = pband_fs;
        if (params.stream_channels > 1)
            pband = pband(:, params.stream_channel + 1);
        end
        [bband, bband_fs] = ddc(pband, pband_fs, pset.cfreq, pset.bwidth, params);
    else
        params.stream_fs = bband_fs;
        bband = complex(bband(:, 1), bband(:, 2));
    end

    [pkt, pkt_bytes, state] = rx(pset, bband, bband_fs, params);
    
    if (params.stream_passband)
        state.after = state.after + (1024 - 128) / pband_fs;
    end

end
