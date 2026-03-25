#################
#RTL simulation
#################
# vcs -R  tb.v REFRACT.v +define+RI=2 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb  -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v
# vcs -R  tb.v REFRACT.v +define+RI=3 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb  -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=4 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb  -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
 vcs -R  tb.v REFRACT.v +define+RI=5 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb  -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=6 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb  -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=7 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb  -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=8 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb  -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=9 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb  -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=10 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb  -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=11 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=12 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=13 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=14 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 
# vcs -R  tb.v REFRACT.v +define+RI=15 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -y /cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v 

#####################
#Gate-Level simuation
#####################
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=2 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=3 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=4 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=5 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=6 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=7 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=8 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=9 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=10 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=11 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=12 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=13 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=14 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
# vcs -R  tb.v REFRACT_syn.v +define+SDF+RI=15 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+REFRACT.fsdb -v /cad/CBDK/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
