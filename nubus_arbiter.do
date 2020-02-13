onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /nubus_arbiter_tb/UA1/nub_idn
add wave -noupdate /nubus_arbiter_tb/UA1/nub_arbn
add wave -noupdate /nubus_arbiter_tb/UA1/arb_ena
add wave -noupdate /nubus_arbiter_tb/UA1/arb_grant_o
add wave -noupdate /nubus_arbiter_tb/UA2/nub_idn
add wave -noupdate /nubus_arbiter_tb/UA2/nub_arbn
add wave -noupdate /nubus_arbiter_tb/UA2/arb_ena
add wave -noupdate /nubus_arbiter_tb/UA2/arb_grant_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 344
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {4199230 ps} {4200041 ps}
