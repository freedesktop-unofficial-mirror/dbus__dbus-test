BINDINGS?=java glib python perl qt4

all: testall analyzeall


analyzeall:
	( for i in $(BINDINGS) ; do \
		  echo "Test results for $${i}" ;\
		  if [[ "`cat $${i}*.server.log 2>/dev/null | wc -l`" == "0" ]]; then \
		  		echo -e "\033[31mFailed to generate test data for $${i}.\033[39m";\
				continue;\
		  fi; \
		  echo -n "   Tested against: " ;\
		  echo -ne "\033[32m";\
		  echo `ls *$${i}*.*.log 2>/dev/null | sed 's/\..*$$//;s/-/\n/g' | sort -u` ;\
		  echo -ne "\033[39m";\
		  echo -n "   Passes: " ;\
		  echo -ne "\033[32m";\
		  cat $${i}*.client.log 2>/dev/null | grep -c pass ;\
		  echo -ne "\033[39m";\
		  echo -n "   Fails: " ;\
		  if grep fail $${i}*.client.log &>/dev/null; then \
			  echo -ne "\033[31m";\
		  else \
			  echo -ne "\033[32m";\
		  fi; \
		  cat $${i}*.client.log 2>/dev/null | grep -c fail ;\
		  echo -ne "\033[39m";\
		  echo -ne "\033[31m";\
		  for j in $${i}*.client.log; do \
		  	 for k in `grep fail $$j  2>/dev/null| cut -d' ' -f 3`; do \
				echo "     " `grep "fail $$k" < $$j | cut -d' ' -f1`: `grep "^report $${k}:" < $$j | cut -d: -f2`; \
			 done ;\
		  done ;\
		  echo -ne "\033[39m";\
		  echo "   $${i} failed to test: " ;\
		  echo -n "   bindings: " ;\
		  echo -ne "\033[33m";\
		  for j in $(BINDINGS); do \
		  		if [ ! -s $${i}-$${j}.server.log ]; then \
					echo -n $${j} " "; \
				fi; \
		  done; \
		  echo -e "\033[39m";\
		  echo -n "   functions: " ;\
		  if grep fail $${i}*.client.log &>/dev/null; then \
			  echo -ne "\033[33m";\
		  else \
			  echo -ne "\033[32m";\
		  fi; \
		  cat *$${i}.server.log 2>/dev/null | grep -c untested$$ ;\
		  echo -ne "\033[33m";\
		  cat *$${i}.server.log 2>/dev/null | grep untested$$ | cut -d' ' -f1 | sed 's/^/      /' | sort -u;\
		  echo -ne "\033[39m";\
	done )
	

testall:
	( for i in $(BINDINGS) ; do \
		 for j in $(BINDINGS) ; do \
			make -s SERV=$$i CLI=$$j check ;\
		 done \
	  done)

clean:
	-rm -- *log
	-rm address
	-rm pid
	-rm tmp-session-bus

check:
	( dbus-daemon --config-file=tmp-session.conf --print-pid --print-address=5 --fork >pid 5>address ; \
	  export DBUS_SESSION_BUS_ADDRESS=$$(cat address) ;\
	  make -sC $(SERV) cross-test-server > $(SERV)-$(CLI).server.log &\
	  make -sC $(CLI) cross-test-client > $(SERV)-$(CLI).client.log ;\
	  kill $$(cat pid) )

