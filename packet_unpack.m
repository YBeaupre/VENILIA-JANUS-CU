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
%| Authors: Ricardo Martins, Unknown                                      |
%+------------------------------------------------------------------------+
%
% PACKET_UNPACK Convert a byte sequence to a JANUS packet structure.
% 
% Inputs:
%   data   Byte array.
%
% Outputs:
%   pkt    Packet structure.
%   err    Error code, 0 for no error, 1 for CRC error.
%
% See also PACKET_NEW, PACKET_PACK.
%

function [pkt err] = packet_unpack(data)
    global verbose;

    defaults;
    
    bin = typecast(uint8(fliplr(data(1 : 8))), 'uint64');
        
    % Initialize packet structure and error code.
    err = 0;
    pkt = packet_new();
    
    % Packet bytes.
    pkt.bytes = data;

    % 4 bits: Version Number.
    pkt.version = bitshift(bin, -60);
    
    % 1 bit: Mobility Flag.
    pkt.mobility = bitand(bitshift(bin, -59), 1);

    % 1 bit: Schedule Flag.
    pkt.schedule = bitand(bitshift(bin, -58), 1);

    % 1 bit: Tx/Rx Flag.
    pkt.tx_rx = bitand(bitshift(bin, -57), 1);

    % 1 bit: Forwarding Capability.
    pkt.forward = bitand(bitshift(bin, -56), 1);

    % 8 bits: Class User Identifier.
    pkt.class_id = bitand(bitshift(bin, -48), 2^8 - 1);
    pkt.class_id_name = user_class_lookup_index(pkt.class_id);
    
    % 6 bits: Application Type.
    pkt.app_type = bitand(bitshift(bin, -42), 2^6 - 1);
    
    if (pkt.schedule == 1)
        % 1 bit: Reservation/Repeat Flag.
        pkt.reserv_repeat = bitand(bitshift(bin, -41), 1);
        % 7 bits: Reservation Time or Repeat Interval Table Index.
        index = uint8(bitand(bitshift(bin, -34), 2^7 - 1));
        if (pkt.reserv_repeat == 0)
            pkt.reserv_time = packet_tx_interval_lookup_index(index, pkt.reserv_repeat);
        else
            pkt.repeat_int = packet_tx_interval_lookup_index(index, pkt.reserv_repeat);
        end
        n_pkt_fields = length(fieldnames(pkt));
        pkt = orderfields(pkt, [(1:8) (n_pkt_fields-1) n_pkt_fields (9:n_pkt_fields-2)]);

        app_data_len = 26;
    else
        app_data_len = 34;
    end

    % 26/34 bits: Application Data.
    pkt.app_data = uint64(bitand(bitshift(bin, -8), 2^app_data_len - 1));

    try
        plugin = sprintf('plugin_%03d_%02d', pkt.class_id, pkt.app_type);
        eval(['[pkt.cargo_size, pkt.app_fields] = ' plugin '(''app_data_decode'', pkt.app_data, app_data_len);']);
    catch ME
        if (verbose)
            disp([plugin ': ' ME.message '.' ]);
        end
    end

    if (app_data_len == 26)
        pkt.app_data = dec2hex(pkt.app_data, 7);
    else
        pkt.app_data = dec2hex(pkt.app_data, 9);
    end

    % 8 bits: CRC.
    pkt.crc = data(8);
    
    % Check CRC.
    my_crc = crc(data(1 : 7), CRC_POLY);
    pkt.crc_validity = (pkt.crc == my_crc);
    err = ~pkt.crc_validity;
end
