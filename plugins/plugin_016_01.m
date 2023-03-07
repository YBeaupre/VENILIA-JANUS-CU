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
% PLUGIN Application data plugin.
%
% Specific class id 16 and application type 1 plugin.
%
% Inputs:
%   type              Function type (encode/decode).
%

function varargout = plugin_016_01(type, varargin)
switch type
    case 'app_data_decode'
        [app_fields, cargo_size] = app_data_decode(varargin{:});
        varargout = { cargo_size, app_fields };
    case 'app_data_encode'
        [app_data, cargo_size, app_fields] = app_data_encode(varargin{:});
        varargout = { app_data, cargo_size, app_fields };
    case 'cargo_decode'
        [ app_fields] = cargo_decode(varargin{:});
        varargout = { app_fields };
    case 'cargo_encode'
        [cargo, cargo_size, app_fields] = cargo_encode(varargin{:});
        varargout = { cargo, cargo_size, app_fields };
    otherwise
        error('janus:plugin_016_01:inv_type', 'unknown function type');
end
end

%+------------------------------------------------------------------------+
%
% APP_DATA_DECODE Decode the application data block.
%
% The purpose of this function is to decode the application data block
% extracting at least the cargo size and other fields.
% The application data block has encoded only the least significant bits (26 or
% 34 bits according to the application data size).
% The application data fields output is a cell of size 1xN (where N is the
% number of fields) containing cells of size 1x2 with the name (string) and the
% value of the fields.
%
% Inputs:
%   app_data          Application data (uint64).
%   app_data_size     Application data size (26 or 34 bits).
%
% Outputs:
%   cargo_size        Cargo size.
%   app_fields        Application data fields.
%

function [app_fields, cargo_size] = app_data_decode(app_data, app_data_size)
% 9 bits: Cargo Size.
cargo_size = double(bitand(app_data, 2^9 - 1));
app_fields{1}{1} = 'Payload_Size';
app_fields{1}{2} = num2str(cargo_size);
app_data = bitshift(app_data, -9);

% 1 bit: acknowledgement requested
app_fields{2}{1} = 'Ack_Request';
app_fields{2}{2} = double(bitand(app_data, 1));
app_data = bitshift(app_data, -1);

% 8 bits: Destination Identifier.
app_fields{3}{1} = 'Destination_Identifier';
app_fields{3}{2} = bitand(app_data, 2^8 - 1);
app_data = bitshift(app_data, -8);

% 8 bits: Station Identifier.
app_fields{4}{1} = 'Station_Identifier';
app_fields{4}{2} = bitand(app_data, 2^8 - 1);

end

%+------------------------------------------------------------------------+
%
% APP_DATA_ENCODE Encode the application data block.
%
% The purpose of this function is to encode application data block according to
% the desired cargo size and the application data fields.
% The desired cargo size represents the minimum desired cargo size.
% The output cargo size is the effective cargo size encoded in the
% application data, and is equal or greater than the desired cargo size.
% The output application data is an uint64 with only the least significant bits
% are encoded (26 or 34 bits according to the application data size).
%
% Inputs:
%   desired_cargo_size     Desired cargo size.
%   app_fields             Application data fields.
%   app_data_size          Application data size (26 or 34 bits).
%
% Outputs:
%   cargo_size             Effective cargo size.
%   app_data               Application data (uint64).
%   app_fields             Updated Application data fields.
%

function [cargo_size, app_data, app_fields] = app_data_encode(desired_cargo_size, app_fields, app_data_size)
app_data = uint64(0);
% default values
ack_req = 0;
station_id = 0;
destination_id = 0;
% cargo size not set
option_cargo_size = -1;
cargo_fields_idx = -1;

for i = 1:length(app_fields)
    switch app_fields{i}{1}
        case 'Station Identifier'
            % 8 bits: Station Identifier.
            station_id = uint64(bitand(str2double(app_fields{i}{2}), 2^8 - 1));
            app_data = bitor(app_data, bitshift(station_id, 18));
            
        case 'Payload'
            % Valid but not used for app_data

        case 'Payload_Size'
            option_cargo_size = str2double(app_fields{i}{2});
            
        case 'Ack_Request'
            % Acknowledge requested
            app_data = bitor(app_data, bitshift(unit64(1), 9));
            
        case 'Destination_Identifier'
            destination_id = ...
                uint64(bitand(str2double(app_fields{i}{2}), 2^8 - 1));
            app_data = bitor(app_data, bitshift(destination_id, 10));
            
        otherwise
            error('janus:plugin_016_01:inv_field', ['unknown field name ' app_fields{i}{1}]);
    end
end

% 9 bits: Cargo Size.
[ user_cargo_size cargo_size ] = packet_cargo_lookup_size(option_cargo_size);
app_data = bitor(app_data, uint64(bitand(cargo_size, 2^9 - 1)));

end

%+------------------------------------------------------------------------+
%
% CARGO_DECODE Decode the cargo data.
%
% The purpose of this function is to decode the cargo or cargo block
% extracting with the knowlege of application data fields.
% The funtion updates the application data fields cells.
%
% Inputs:
%   cargo             Cargo cargo data (uint64).
%   cargo_size        Cargo size.
%   app_fields        Application data fields.
%
% Outputs:
%   app_fields        Updated application data fields.
%
function [ app_fields ] = cargo_decode(cargo, cargo_size, ...
    app_fields)
if (cargo_size > 0)
      
    % maximum cargo to apply CRC-8
    JANUS_MAX_SIZE_CRC_8 = 64;
    if (cargo_size <= JANUS_MAX_SIZE_CRC_8 + 1)
        user_cargo_size = cargo_size - 1;
        % using the same CRC of the packet
        CRC_POLY = 7;
        computed_crc = uint8(crc(cargo(1:user_cargo_size), CRC_POLY));
    else
        user_cargo_size = cargo_size - 2;
        computed_crc = crc16(cargo(1:user_cargo_size), 0);
    end
    
    next_idx = length(app_fields) + 1;
    app_fields{next_idx}{1} = 'Payload';
    app_fields{next_idx}{2} = cargo(1 : user_cargo_size);
    
    if (cargo(user_cargo_size + 1:end) ~= computed_crc)
        disp ('janus:rx:plugin_016_01:invalid cargo CRC')
    end
end
end

%+------------------------------------------------------------------------+
%
% CARGO_ENCODE Encode the cargo data.
%
% The purpose of this function is to encode cargo data according to
% the application data fields.
% This function return the cargo size.
% The output cargo is a vector of uint8.
%
% Inputs:
%   app_fields             Application data fields.
%   cargo_size             Desired cargo size.
%
% Outputs:
%   cargo                  Cargo data vector (uint8).
%   cargo_size             Effective cargo size.
%   app_fields             Updated Application data fields.
%

function [cargo, cargo_size, app_fields] = cargo_encode(app_fields, cargo_size)
cargo = uint8([]);

for idx1 = 1:length(app_fields)
    if (strcmp(app_fields{idx1}{1}, 'Payload_Size'))
        [d_cargo_size cargo_size] = ...
            packet_cargo_lookup_size(str2num(app_fields{idx1}{2}));
        
        for idx2 = 1:length(app_fields)
            switch app_fields{idx2}{1}
                case 'Payload'
                    % arbitrary data uint8 array
                    cargo = uint8(app_fields{idx2}{2}(1:d_cargo_size));
            end
        end
        
        % maximum cargo to apply CRC-8
        JANUS_MAX_SIZE_CRC_8 = 64;
        % determine whether using CRC-8 or CRC-16
        if (d_cargo_size <= JANUS_MAX_SIZE_CRC_8)
            % using the same CRC of the packet
            CRC_POLY = 7;
            cargo = [cargo uint8(crc(cargo, CRC_POLY))];
        else
            cargo = [cargo crc16(cargo, 0)];
        end
    end
end
end

function [user_cargo_size, effective_size] = packet_cargo_lookup_size(dsize)
% 9 bits reserverd for cargo size
MAX_SIZE = 2^9 - 1;
% maximum cargo to apply CRC-8
JANUS_MAX_SIZE_CRC_8 = 64;

% adding crc size
if (dsize <= JANUS_MAX_SIZE_CRC_8)
    user_cargo_size = dsize;
    effective_size = user_cargo_size + 1;
else
    user_cargo_size = min(MAX_SIZE - 2, dsize);
    effective_size = user_cargo_size + 2;
end
end

% CRC Compute the CRC16 of a byte sequence.
%
% Inputs:
%   data  unit8 array of byte sequence.
%   crc   Initial CRC (0 if not given).
%
%  Outputs:
%   crc   CRC16 of input byte sequence.
%
function crc = crc16(data, crc)

crc16_ibm_table = uint16([
        0, 49345, 49537,   320, 49921,   960,   640, 49729, ...
    50689,  1728,  1920, 51009,  1280, 50625, 50305,  1088, ...
    52225,  3264,  3456, 52545,  3840, 53185, 52865,  3648, ...
     2560, 51905, 52097,  2880, 51457,  2496,  2176, 51265, ...
    55297,  6336,  6528, 55617,  6912, 56257, 55937,  6720, ...
     7680, 57025, 57217,  8000, 56577,  7616,  7296, 56385, ...
     5120, 54465, 54657,  5440, 55041,  6080,  5760, 54849, ...
    53761,  4800,  4992, 54081,  4352, 53697, 53377,  4160, ...
    61441, 12480, 12672, 61761, 13056, 62401, 62081, 12864, ...
    13824, 63169, 63361, 14144, 62721, 13760, 13440, 62529, ...
    15360, 64705, 64897, 15680, 65281, 16320, 16000, 65089, ...
    64001, 15040, 15232, 64321, 14592, 63937, 63617, 14400, ...
    10240, 59585, 59777, 10560, 60161, 11200, 10880, 59969, ...
    60929, 11968, 12160, 61249, 11520, 60865, 60545, 11328, ...
    58369,  9408,  9600, 58689,  9984, 59329, 59009,  9792, ...
     8704, 58049, 58241,  9024, 57601,  8640,  8320, 57409, ...
    40961, 24768, 24960, 41281, 25344, 41921, 41601, 25152, ...
    26112, 42689, 42881, 26432, 42241, 26048, 25728, 42049, ...
    27648, 44225, 44417, 27968, 44801, 28608, 28288, 44609, ...
    43521, 27328, 27520, 43841, 26880, 43457, 43137, 26688, ...
    30720, 47297, 47489, 31040, 47873, 31680, 31360, 47681, ...
    48641, 32448, 32640, 48961, 32000, 48577, 48257, 31808, ...
    46081, 29888, 30080, 46401, 30464, 47041, 46721, 30272, ...
    29184, 45761, 45953, 29504, 45313, 29120, 28800, 45121, ...
    20480, 37057, 37249, 20800, 37633, 21440, 21120, 37441, ...
    38401, 22208, 22400, 38721, 21760, 38337, 38017, 21568, ...
    39937, 23744, 23936, 40257, 24320, 40897, 40577, 24128, ...
    23040, 39617, 39809, 23360, 39169, 22976, 22656, 38977, ...
    34817, 18624, 18816, 35137, 19200, 35777, 35457, 19008, ...
    19968, 36545, 36737, 20288, 36097, 19904, 19584, 35905, ...
    17408, 33985, 34177, 17728, 34561, 18368, 18048, 34369, ...
    33281, 17088, 17280, 33601, 16640, 33217, 32897, 16448, ...
    ]);

if (nargin < 2)
    crc = 0;
end
crc = uint16(crc);

mask2bytes = uint16(hex2dec('00ff'));

for i = 1 : length(data)
    idx = bitand(bitxor(crc, typecast([data(i) 0], 'uint16')), ...
        mask2bytes);
    t= crc16_ibm_table(idx + 1);
    crc = bitxor(bitshift(crc, -8), crc16_ibm_table(idx + 1));    
end

crc = typecast(crc, 'uint8');
end
