
debugout=1
exports=-I./sub_module/libmpegts/crc/

target_srcs=./sub_module/libmpegts/crc/crc.c
target_srcs+=./t_token.cpp 
target_srcs+=./function.cpp 

all:
ifeq ($(debugout), 1)
	bison -t -v ttlcc.y -o parser.cpp
	flex -d -o tokens.cpp ttlcc.l
	g++ -O2 -o ttlcc parser.cpp tokens.cpp $(target_srcs) $(exports) -lfl -ly -lm -DYYERROR_VERBOSE -DDEBUGOUT -DYYDEBUG=1
else
	bison ttlcc.y -o parser.cpp
	flex -o tokens.cpp ttlcc.l
	g++ -O2 -o ttlcc parser.cpp tokens.cpp $(target_srcs) $(exports) -lfl -ly -lm -DYYDEBUG=0
endif

clean:
	rm -f parser.cpp tokens.cpp parser.hpp ttlcc