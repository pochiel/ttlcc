# デバッグフラグ
debugout=1

# 外部ライブラリインポート咲
exports=-I./sub_module/libmpegts/crc/

# ttlcc のターゲットソース
target_srcs_c=./sub_module/libmpegts/crc/crc.c
target_srcs_c+=./t_token.cpp 
target_srcs_c+=./function.cpp 
target_srcs_c+=./common.cpp 
target_srcs_c+=./variable_manager.cpp 

# ttlcc のターゲットオブジェクト
tmp_OBJ_c = $(target_srcs_c:.cpp=.o)
OBJ_c = $(tmp_OBJ_c:.c=.o)

# ttlcpp のターゲットソース
target_srcs_pp=$(target_srcs_c)
#target_srcs_pp+=

# ttlcc のターゲットオブジェクト
tmp_OBJ_pp = $(target_srcs_pp:.cpp=.o)
OBJ_pp = $(tmp_OBJ_pp:.c=.o)

# make clean で消えてほしいゴミファイル
target_remove_clean=parser.output
target_remove_clean+=pp_parser.output
target_remove_clean+=parser.cpp
target_remove_clean+=pp_parser.cpp
target_remove_clean+=tokens.cpp
target_remove_clean+=pp_tokens.cpp
target_remove_clean+=parser.hpp
target_remove_clean+=pp_parser.hpp
target_remove_clean+=ttlcc
target_remove_clean+=ttlcpp
target_remove_clean+=ttlc_conflict.log
target_remove_clean+=ttlcpp_conflict.log
target_remove_clean+=ttlcc.tab.c
target_remove_clean+=ttlcc.tab.h
target_remove_clean+=ttlcpp.tab.c
target_remove_clean+=ttlcpp.tab.h

# LINK Target
target_link_lib_debug= -lfl -lm -DYYERROR_VERBOSE -DDEBUGOUT -DYYDEBUG=1
target_link_lib= -lfl -lm -DYYDEBUG=0

# 最終ターゲット
all: ttlcc ttlcpp

# プリプロセッサ
ttlcpp: $(OBJ_pp) pp_parser.o pp_tokens.o
ifeq ($(debugout), 1)
	g++ -o ttlcpp $(OBJ_pp) pp_parser.o pp_tokens.o $(target_link_lib_debug)
else
	g++ -o ttlcpp $(OBJ_pp) pp_parser.o pp_tokens.o $(target_link_lib)
endif

# コンパイラ
ttlcc: $(OBJ_c) parser.o tokens.o
	echo "OBJ_c=" $(OBJ_c) 
	echo "OBJ_pp=" $(OBJ_pp) 
ifeq ($(debugout), 1)
	g++ -o ttlcc $(OBJ_c) parser.o tokens.o $(target_link_lib_debug)
else
	g++ -o ttlcc $(OBJ_c) parser.o tokens.o $(target_link_lib)
endif

pp_parser.cpp parser.cpp: ttlcpp.y ttlcc.y
ifeq ($(debugout), 1)
	# プリプロセッサ
	bison -t -v ttlcpp.y -o pp_parser.cpp
	bison ttlcpp.y -r all --report-file=ttlcpp_conflict.log

	# コンパイラ
	bison -t -v ttlcc.y -o parser.cpp
	bison ttlcc.y -r all --report-file=ttlc_conflict.log
else
	# プリプロセッサ
	bison ttlcpp.y -o pp_parser.cpp

	# コンパイラ
	bison ttlcc.y -o parser.cpp
endif

pp_tokens.cpp tokens.cpp: ttlcpp.l ttlcc.l
ifeq ($(debugout), 1)
	# プリプロセッサ
	flex -d -o pp_tokens.cpp ttlcpp.l

	# コンパイラ
	flex -d -o tokens.cpp ttlcc.l
else
	# プリプロセッサ
	flex -o pp_tokens.cpp ttlcpp.l

	# コンパイラ
	flex -o tokens.cpp ttlcc.l
endif

.cpp.o:
ifeq ($(debugout), 1)
	g++ -O0 -g -c $< $(exports) $(target_link_lib_debug)
else
	g++ -O2 -c $< $(exports) $(target_link_lib)
endif

clean:
	rm -f $(target_remove_clean) *.o