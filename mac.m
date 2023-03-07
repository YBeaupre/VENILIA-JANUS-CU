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
%  JANUS MAC simulation on recorded passband waveform.
%
% Inputs:
%    pset_file          Parameter set file (CSV).
%    pset_id            Parameter set Id.
%    varargin           Optional parameters.
%
% Outputs:
%    start_busy         Vector with start time of busy periods.
%    end_busy           Vector with end time of busy periods.
%    start_busy_guard   Vector with start time of guard periods.
%    end_busy_guard     Vector with end time of guard periods.  
%    
% See also RX, SIMPLE_RX, PARAMETERS.



function [start_busy, end_busy, start_busy_guard, end_busy_guard] = mac(pset_file, pset_id, varargin)

    global verbose;
    
    params = parameters(struct(varargin{:}));    
  
    % Load parameter set configuration.
    pset = pset_load(pset_file, pset_id, params);
  
    verbose = params.verbose;

    %% Initialize output variables to sane values.
    pkt = {};
    pkt_bytes = [];
    state = {};
    state.pset_id = pset.id;
    state.pset_name = pset.name;
    state.cfreq = pset.cfreq;
    state.bwidth = pset.bwidth;
    state.chip_frq = pset.chip_frq;
    state.chip_dur = pset.chip_dur;

    state.nblock = pset.nblock;
    
    if (pset.id ~= 1)
        error('janus:mac:invalid_pset', 'unsupported MAC for this parameter set');
    end

     switch (params.stream_driver)
      case 'mem'
        eval(['global ' params.stream_driver_args ]);
        if (params.stream_passband)
            eval([ 'pband = ' params.stream_driver_args ';' ]);
            pband_fs = params.stream_fs;
        else
            % eval([ 'bband = ' params.stream_driver_args ';' ]);
            % bband_fs = params.stream_fs;
            error('janus:mac:invalid_pset', 'baseband not supported');
        end
        
      case 'wav'
        if (params.stream_passband)
            [pband, pband_fs] = audioread(params.stream_driver_args);
        else
            % [bband, bband_fs] = audioread(params.stream_driver_args);
            error('janus:mac:invalid_pset', 'baseband not supported');
        end
        
      case 'mat'
        mat = load(params.stream_driver_args);
        params.stream_passband = mat.params.stream_passband;
        if (params.stream_passband)
            pband = mat.signal;
            pband_fs = mat.params.stream_fs;
        else
            % bband = mat.signal;
            % bband_fs = mat.params.stream_fs;
            error('janus:mac:invalid_pset', 'baseband not supported');
        end
        
      otherwise
        error('janus:mac:inv_stream', 'unsupported stream type');
    end

    % Number of samples in a chip.
    chip_nsample = round(pset.chip_dur * pband_fs);
    
    % in-band filtering
    [ signal_b ]  = [(-pset.nblock - 1)  pset.nblock] * pset.chip_frq ...
        + state.cfreq;

    nH=12;  % Order

    fH= [ (signal_b(1) - pset.chip_frq / 2)  (signal_b(2) + pset.chip_frq / 2) ] ./ (pband_fs /2);

    % inband filter is not specified in the technical description of the
    % STANAG
    [bH, aH] = cheby2(nH, 80, fH,'bandpass');

    %[h,w] = freqz(bH,aH,2048);
    %figure(1);
    %plot(fH *pband_fs/2,[0 0],w/pi*pband_fs/2,20*log10(abs(h)))
    
    pband_filt = filtfilt(bH, aH, pband);
    
    i_power = pband_filt .* conj(pband_filt);
    
    if (verbose > 0)
      figure(2)
      plot ((0 : length(i_power) - 1) / pband_fs ,i_power);
      title('Istantanous Energy');
      xlabel('Time [s]');
    end
    
    % do the moving averages 
    step_l_bg = 352 * chip_nsample;
    step_bg = ones(step_l_bg, 1) / step_l_bg;
    flen_bg = step_l_bg + length(i_power) - 1;
    
    step_l_eb = 16 * chip_nsample;
    step_eb = ones(step_l_eb, 1) / step_l_eb;
    flen_eb = step_l_eb + length(i_power) - 1;

    mov_avg_bg = ifft(fft(i_power, flen_bg) .* fft(step_bg, flen_bg));
    mov_avg_eb = ifft(fft(i_power, flen_eb) .* fft(step_eb, flen_eb));
    mov_avg_bg = mov_avg_bg(step_l_bg -1 : end);
    mov_avg_eb = mov_avg_eb(step_l_eb -1 : end);
    
    % Test for the 3 dB (double) criteria
    busy_test = mov_avg_eb > 2 * mov_avg_bg;
    
    busy_transisitions = [ busy_test; 0]  - [ 0; busy_test ];
    
    start_busy = find(busy_transisitions == 1);
    end_busy = find(busy_transisitions == -1) - 1;
   
    busy_gurad = 176 * chip_nsample;
    for start_idx = end_busy'
        busy_test(start_idx : min(start_idx + busy_gurad, length(busy_test))) = 1;
    end
    
    busy_transisitions = [ busy_test; 0]  - [ 0; busy_test ];
    start_busy_guard = (find(busy_transisitions == 1) - 1) / pband_fs;
    end_busy_guard = (find(busy_transisitions == -1) - 2) / pband_fs;
    
    start_busy = (start_busy - 1) / pband_fs;
    end_busy = (end_busy - 1) / pband_fs;

    if (verbose > 0)
      figure(1)
      clf;
 
      if (~ isempty(start_busy))
          max_eb = max(mov_avg_eb) * 1.1;
          y_plot = repmat([0 max_eb max_eb 0]', length(start_busy_guard), 1);
          area((sort([start_busy_guard; start_busy_guard; end_busy_guard; end_busy_guard])), ...
              y_plot, 'FaceColor',[0.96 0.88 .1],'EdgeColor','none');
          hold on

          max_eb = max(mov_avg_eb) * 1.1;
          y_plot = repmat([0 max_eb max_eb 0]', length(start_busy), 1);
          area((sort([start_busy; start_busy; end_busy; end_busy])), ...
              y_plot, 'FaceColor',[1 0.666 0],'EdgeColor','none');
      end
      
      hp = plot ((0 : length(mov_avg_bg) - 1) / pband_fs ,[mov_avg_bg mov_avg_eb]);
      hp(1).Color = [0.3 0.3 1.0];
      hp(2).Color = [0.1 0.6 0.4];
      
      if (~ isempty(start_busy))
          legend({'guard', 'busy','background', 'energy in band'});
      else
          legend({'background', 'energy in band'});
      end
      
      title('Short time / Slow time');
      xlabel('Time [s]');
    end
    
        
end
