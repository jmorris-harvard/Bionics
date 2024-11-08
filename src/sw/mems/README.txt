programs to run using nipcb utility script

.mem files in this directory will be automatically detected by utility script
and added as valid commands (even if not compatible with current bitfile)

NAME			COMPATIBLE_BITFILE	DESC
counter		synth_11-07					slow counter on leds (idle else)
slider		synth_11-07					slow shifter on leds (idle else)
stim			synth_11-07					starts 50Hz, 1V/Rstim, 8 cycle stimulation
recv			synth_11-07					starts recording on 4 channels, pga gain 1, 100 cycle stall
															reads out initial 6400 results to out.csv
