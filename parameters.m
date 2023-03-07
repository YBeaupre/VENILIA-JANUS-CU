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
%| Authors: Ricardo Martins, Luigi Elia D'Amaro                           |
%+------------------------------------------------------------------------+
%
% PARAMETERS Retrieve JANUS parameters.
%
%   PARAMETERS() returns a structure with the required default 
%   parameters to encode/decode a JANUS compliant waveform.
%  
%   PARAMETERS(args) adds all the missing parameters to structure
%   'args'. These parameters are initialized to default JANUS
%   compliant values.
%
%   The user may modify the fields of the returned structure to change
%   the format of the generated waveform and finetune the behaviour
%   of the encoder/decoder. Waveforms generated using user-defined
%   parameters might not be JANUS compliant.
%
% Inputs:
%    iargs     Structure containing parameters.
%
% Outputs:
%    oargs     Structure containing all valid JANUS parameters.
%

function oargs = parameters(iargs)
    defaults;

    if (nargin < 1)
        iargs = [];
    end

    oargs = iargs;

    % Verbose: vebosity level.
    if (~isfield(oargs, 'verbose'))
        oargs.verbose = 0;
    end

    % Initial fixed sequence of 32 chips (hex).
    if (~isfield(oargs, 'sequence_32_chips'))
        oargs.sequence_32_chips = 'AEC7CD20'; %10101110110001111100110100100000
    end
    oargs.c32_sequence = de2bi(hex2dec(oargs.sequence_32_chips), 32, 'left-msb');

    % Chip length dyadic exponent.
    if (~isfield(oargs, 'chip_len_exp'))
        oargs.chip_len_exp = 0;
    end
    if (oargs.chip_len_exp < 0)
        oargs.chip_len_exp = 0;
    end
    oargs.pset_chip_len_mul = 2 ^ fix(oargs.chip_len_exp);

    % Stream parameters.

    % Stream: Driver (wav, mat, mem).
    if (~isfield(oargs, 'stream_driver'))
        oargs.stream_driver = 'wav';
    end

    % Stream: Driver Arguments.
    if (~isfield(oargs, 'stream_driver_args'))
        switch (oargs.stream_driver)
          case 'wav'
            oargs.stream_driver_args = 'janus.wav';
          case 'mat'
            oargs.stream_driver_args = 'janus.mat';
        end
    end

    % Stream: Sampling Frequency (Hz). Zero means 'choose the first
    % suitable sampling frequency from a list of common frequencies'.
    if (~isfield(oargs, 'stream_fs'))
        oargs.stream_fs = 0;
    end

    % Stream: Format (U8, S16, S24, FLOAT).
    if (~isfield(oargs, 'stream_format'))
        oargs.stream_format = 'S16';
    end

    % Stream: Bits per sample.
    switch (oargs.stream_format)
      case 'U8'
        oargs.stream_bps = 8;
      case 'S16'
        oargs.stream_bps = 16;
      case 'S24'
        oargs.stream_bps = 24;
      case 'FLOAT'
        oargs.stream_bps = 32;
      otherwise
        error('janus:parameters:inv_stream', 'unsupported stream format');
    end

    % Stream: Passband or Baseband Signal.
    if (~isfield(oargs, 'stream_passband'))
        oargs.stream_passband = 1;
    end
    
    % Stream: Number of channels
    if (~isfield(oargs, 'stream_channels'))
        oargs.stream_channels = 1;
    end
    
     % Stream: Channel to use
    if (~isfield(oargs, 'stream_channel'))
        oargs.stream_channel = 0;
    end

    % Stream: amplitude factor.
    if (~isfield(oargs, 'stream_amp'))
        oargs.stream_amp = 0.95;
    end

    % Stream: force number of output samples to be a multiple
    % of a given number.
    if (~isfield(oargs, 'stream_mul'))
        oargs.stream_mul = 0;
    end

    % Tx parameters.

    % Padding: enabled/disabled.
    if (~isfield(oargs, 'pad'))
        oargs.pad = 1;
    end

    % Wake Up Tones: enabled/disabled.
    if (~isfield(oargs, 'wut'))
        oargs.wut = 0;
    end

    % Packet: Mobility Flag.
    if (~isfield(oargs, 'packet_mobility'))
        oargs.packet_mobility = 0;
    end

    % Packet: Tx/Rx Flag.
    if (~isfield(oargs, 'packet_tx_rx'))
        oargs.packet_tx_rx = 1;
    end

    % Packet: Forwarding Capability.
    if (~isfield(oargs, 'packet_forward'))
        oargs.packet_forward = 0;
    end

    % Packet: Class User Identifier.
    if (~isfield(oargs, 'packet_class_id'))
        oargs.packet_class_id = JANUS_RI_CLASS_ID;
    end

    % Packet: Application Type.
    if (~isfield(oargs, 'packet_app_type'))
        oargs.packet_app_type = 0;
    end

    % Packet: Reservation Time.
    if (~isfield(oargs, 'packet_reserv_time'))
        oargs.packet_reserv_time = 0.0;
    end

    % Packet: Repeat Interval.
    if (~isfield(oargs, 'packet_repeat_int'))
        oargs.packet_repeat_int = 0.0;
    end

    % Packet: Application Data.
    if (~isfield(oargs, 'packet_app_data'))
        oargs.packet_app_data = '';
    end

    % Packet: Application Data Fields.
    if (~isfield(oargs, 'packet_app_fields'))
        oargs.packet_app_fields = [];
    end

    % Packet: Cargo.
    if (isfield(oargs, 'packet_cargo'))
        if (ischar(oargs.packet_cargo))
            oargs.packet_cargo = uint8(oargs.packet_cargo);
        else
            error('janus:parameters:inv_packet_cargo', 'unsupported cargo format');
        end
    end

    % Rx parameters.

    % Doppler correction: enabled/disabled.
    if (~isfield(oargs, 'doppler_correction'))
        oargs.doppler_correction = 1;
    end

    % Doppler correction: maximum speed [m/s].
    if (~isfield(oargs, 'doppler_max_speed'))
        oargs.doppler_max_speed = 5;
    end
end
