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
%| Author: Ricardo Martins                                                |
%+------------------------------------------------------------------------+
%
% PACKET_NEW Create a JANUS packet structure.
% 
% Inputs:
%   params   Optional parameters.
%  pset_id   Parameter set Id.
%
% Outputs:
%   pkt      Packet structure.
%
% See also PACKET_PACK, PACKET_UNPACK.
%

function pkt = packet_new(params, pset_id)
    defaults;

    if (nargin < 1)
        params = parameters({});
        if (nargin < 2)
            pset_id = 0;
        end
    end

    pkt.bytes = [];
    
    % Version Number.
    pkt.version = JANUS_VERSION;

    % Mobility Flag.
    pkt.mobility = params.packet_mobility;

    % Schedule Flag.
    pkt.schedule = 0;

    % Tx/Rx capability.
    pkt.tx_rx = params.packet_tx_rx;

    % Forwarding capability.
    pkt.forward = params.packet_forward;

    % Class User Id.
    pkt.class_id = params.packet_class_id;
    
    % Class User name.
    pkt.class_id_name = '';

    % Application Type.
    pkt.app_type = params.packet_app_type;

    if (params.packet_reserv_time > 0)
        % Schedule Flag.
        pkt.schedule = 1;
        % Reservation Time or Repeat Interval Flag.
        pkt.reserv_repeat = 0;
        % Reservation Time.
        pkt.reserv_time = params.packet_reserv_time;
    elseif (params.packet_repeat_int > 0)
        % Schedule Flag.
        pkt.schedule = 1;
        % Reservation Time or Repeat Interval Flag.
        pkt.reserv_repeat = 1;
        % Repeat Interval.
        pkt.repeat_int = params.packet_repeat_int;
    end

    % Cargo Size.
    pkt.cargo_size = 0;

    % Application data.
    pkt.app_data = intmax('uint64');
    if (~isempty(params.packet_app_data))
        pkt.app_data = uint64(hex2dec(params.packet_app_data));
    elseif (~isempty(params.packet_app_fields))
        args = textscan(params.packet_app_fields, '%s', 'Delimiter', ',=');
        pkt.packet_app_fields = cell(2,1);
        for c = 0 : length(args{1}) / 2 - 1
            pkt.packet_app_fields{c + 1} = args{1}(2 * c + 1:2 * c + 2);
        end
    end

    % CRC.
    pkt.crc = 0;

    % Computed CRC Validity.
    pkt.crc_validity = 0;

    % Optional cargo.
    if (isfield(params, 'packet_cargo'))
        pkt.cargo = params.packet_cargo;
        pkt.cargo_size = length(params.packet_cargo);
    else
        pkt.cargo = '';        
    end
end
