all:
	cd sim/test && ./makeData.py > /dev/null
	vivado -mode batch -source script/gen_project_and_ip.tcl

clean:
	rm -rf ParallelToStream2 ../../ip_repo/ParallelToStream2 sim/test/*.txt vivado* *.log 
