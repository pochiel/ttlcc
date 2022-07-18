
debugout=0

all:
ifeq ($(debugout), 1)
	bison -t -v ttlcc.y -o parser.cpp
	flex -d -o tokens.cpp ttlcc.l
	g++ -O2 -o ttlcc parser.cpp tokens.cpp t_token.cpp -lfl -ly -lm -DYYERROR_VERBOSE -DDEBUGOUT -DYYDEBUG=1
else
	bison ttlcc.y -o parser.cpp
	flex -o tokens.cpp ttlcc.l
	g++ -O2 -o ttlcc parser.cpp tokens.cpp t_token.cpp -lfl -ly -lm -DYYDEBUG=0
endif

clean:
	rm -f parser.cpp tokens.cpp parser.hpp ttlcc