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

# ttlcpp のターゲットソース
target_srcs_pp=$(target_srcs_c)
#target_srcs_pp+=

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

# 最終ターゲット
all: ttlcc ttlcpp

# プリプロセッサ
ttlcpp:
ifeq ($(debugout), 1)
	bison -t -v ttlcpp.y -o pp_parser.cpp
	bison ttlcpp.y -r all --report-file=ttlcpp_conflict.log
	flex -d -o pp_tokens.cpp ttlcpp.l
	g++ -O0 -g -o ttlcpp pp_parser.cpp pp_tokens.cpp $(target_srcs_pp) $(exports) -lfl -lm -DYYERROR_VERBOSE -DDEBUGOUT -DYYDEBUG=1
else
	bison ttlcpp.y -o pp_parser.cpp
	flex -o pp_tokens.cpp ttlcpp.l
	g++ -O2 -o ttlcpp pp_parser.cpp pp_tokens.cpp $(target_srcs_pp) $(exports) -lfl -lm -DYYDEBUG=0
endif

# コンパイラ
ttlcc:
ifeq ($(debugout), 1)
	bison -t -v ttlcc.y -o parser.cpp
	bison ttlcc.y -r all --report-file=ttlc_conflict.log
	flex -d -o tokens.cpp ttlcc.l
	g++ -O0 -g -o ttlcc parser.cpp tokens.cpp $(target_srcs_c) $(exports) -lfl -lm -DYYERROR_VERBOSE -DDEBUGOUT -DYYDEBUG=1
else
	bison ttlcc.y -o parser.cpp
	flex -o tokens.cpp ttlcc.l
	g++ -O2 -o ttlcc parser.cpp tokens.cpp $(target_srcs_c) $(exports) -lfl -lm -DYYDEBUG=0
endif

clean:
	rm -f $(target_remove_clean)