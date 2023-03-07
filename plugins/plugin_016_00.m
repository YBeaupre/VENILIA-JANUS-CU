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
% Specific class id 16 and application type 0 plugin.
%
% Inputs:
%   type              Function type (encode/decode).
%

function varargout = plugin_016_00(type, varargin)
    switch type
        case 'app_data_decode'
            [app_fields, cargo_size] = app_data_decode(varargin{:});
            varargout = { cargo_size, app_fields };
        case 'app_data_encode'
            [app_data, cargo_size, app_fields] = app_data_encode(varargin{:});
            varargout = { app_data, cargo_size, app_fields};
        case 'cargo_decode'
            [ app_fields] = cargo_decode(varargin{:});
            varargout = { app_fields };
        case 'cargo_encode'
            [cargo, cargo_size, app_fields ] = cargo_encode(varargin{:});
            varargout = { cargo, cargo_size, app_fields };
        otherwise
            error('janus:plugin_016_00:inv_type', 'unknown function type');
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
    % 6 bits: Cargo Size.
    cargo_size = packet_cargo_lookup_index(double(bitand(app_data, 2^6 - 1)));
    app_data = bitshift(app_data, -6);

    % 12 bits: Parameter Set Identifier.
    app_fields{2}{1} = 'Parameter Set Identifier';
    app_fields{2}{2} = bitand(app_data, 2^12 - 1);
    app_data = bitshift(app_data, -12);

    % 8 bits: Station Identifier.
    app_fields{1}{1} = 'Station Identifier';
    app_fields{1}{2} = bitand(app_data, 2^8 - 1);
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

    for i = 1:length(app_fields)
        switch app_fields{i}{1}
            case 'Station Identifier'
                % 8 bits: Station Identifier.
                station_id = uint64(bitand(str2double(app_fields{i}{2}), 2^8 - 1));
                app_data = bitor(app_data, bitshift(station_id, 18));
            case 'Parameter Set Identifier'
                % 12 bits: Parameter Set Identifier.
                pset_id = uint64(bitand(str2double(app_fields{i}{2}), 2^12 - 1));
                app_data = bitor(app_data, bitshift(pset_id, 6));
            case 'Payload'
                % arbitrary data uint8 array
                desired_cargo_size = length(app_fields{i}{2});
            otherwise
                error('janus:plugin_016_00:inv_field', ['unknown field name ' app_fields{i}{1}]);
        end
    end
    
    % 6 bits: Cargo Size.
    [idx, cargo_size] = packet_cargo_lookup_size(desired_cargo_size);
    app_data = bitor(app_data, uint64(bitand(idx, 2^6 - 1)));
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
        next_idx = length(app_fields) + 1;
        app_fields{next_idx}{1} = 'Payload';
        app_fields{next_idx}{2} = cargo(1 : cargo_size); 
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

function [cargo, cargo_size, app_fields ] = cargo_encode(app_fields, cargo_size)
cargo = uint8([]);
for i = 1:length(app_fields)
    switch app_fields{i}{1}
        case 'Payload'
            % arbitrary data uint8 array      
            cargo = app_fields{i}{2};
            cargo_size = length(cargo);
    end
end
end

function size = packet_cargo_lookup_index(index)
    if (index == 0)
        size = 0;
    elseif (index < 4)
        size = 2 ^ (index - 1);
    else
        size = 8 * (index - 3);
    end
end

function [index, esize] = packet_cargo_lookup_size(dsize)
    if (dsize < 3)
        index = dsize;
        esize = dsize;
    elseif (dsize < 5)
        index = 3;
        esize = 4;
    else
        esize = bitand((dsize - 1), 65528) + 8;
        index = 4 + ((esize - 8) / 8);
    end
end
