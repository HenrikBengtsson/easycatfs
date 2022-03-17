shellcheck:
	{ \
	    cd bin/;\
	    shellcheck -s bash -x incl/*.sh; \
	    shellcheck -x easycatfs; \
	}
	shellcheck tests/*.sh


