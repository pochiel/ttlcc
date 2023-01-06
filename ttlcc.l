%{
#include "t_token.hpp"
#include "parser.hpp"
#include <string.h>
#include <string>
#include <regex>

extern FILE * output_file_ptr;
extern "C" int yylex();
extern int yyparse();
#ifdef DEBUGOUT
extern int yydebug;
#endif

// _b__buf__ は char *
#define SET_YYLVAL(_b__buf__)	{																\
	std::string temp;																			\
	yylval.ctype = new t_token();																\
	yylval.ctype->token_str = std::regex_replace(_b__buf__, std::regex("\n|\r\n|\r"), "");		\
}

// _b__buf__ は char *
#define SET_RETURN_TYPE(_b__type__)	{																\
	std::string temp;																			\
	yylval.ctype = new t_token();																\
	yylval.ctype->type = _b__type__;															\
}

%}

white       [ |\t|\r|\n]
integer     [0-9]+
symbol      [=+\-\^*/();\n]
letter      [_[:alpha:]][_[:alnum:]]*
other       .
other_cr	[[.]]
all_of_char	[^\{\};]
DIGIT    [[:digit:]]
NUMBER   {integer}

%x ST_COMMENT
%x ST_STR_RETERAL

%%

{white}+

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* 関数宣言を検出して通知する
	*	責務：return(FUNCTION)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
	func								 	{	return(FUNCTION);		}
	endfunc								 	{	return(ENDFUNCTION);	}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* if条件を検出して通知する
	*	責務：return(IF)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
	if								 		{	return(IF);			}
	else								 	{	return(ELSE);		}
	then								 	{	return(THEN);		}
	endif								 	{	return(ENDIF);		}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* for 検出して通知する
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
	for										{	return(FOR);		}
	to										{	return(TO);			}
	step									{	return(STEP);		}
	next									{	return(NEXT);		}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* do while 系を検出して通知する
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
	while									{	return(WHILE);		}
	endwhile								{	return(ENDWHILE);	}
	do										{	return(DO);			}
	loop									{	return(LOOP);		}
	break									{	return(BREAK);		}
	continue								{	return(CONTINUE);	}

%{  /*********************************************************************************
	*  行末を検出する。
	*/ %}
	;										{	return(CR);						}

%{  /*********************************************************************************
	*  returnを検出する。
	*/ %}
	"return"									{	return(RETRN);			}

%{  /*********************************************************************************
	*  int/string/void を検出する。
	*/ %}
	int										{	SET_RETURN_TYPE(TYPE_INT); return(INT);			}
	string									{	SET_RETURN_TYPE(TYPE_STRING); return(STRING);	}
	void									{	SET_RETURN_TYPE(TYPE_VOID); return(VOID);		}

%{  /*********************************************************************************
	*  演算子を検出する。
	*/ %}
	"("										{	return(BRACE);						}
	")"										{	return(END_BRACE);					}
	"not"									{	return(BIT_NOT);					}
	"~"										{	return(BIT_NOT);					}
	"!"										{	return(LOGICAL_NOT);				}
	"+"										{	return(PLUS);						}
	"-"										{	return(MINUS);						}
	"*"										{	return(ASTA);						}
	"/"										{	return(SLASH);						}
	"%"										{	return(MOD);						}
	"="										{	return(EQUAL);						}
	"<<"									{	return(LEFT_SHIFT);					}
	">>"									{	return(RIGHT_SHIFT);				}
	"<<<"									{	return(LEFT_SHIFT_LOGIC);			}
	">>>"									{	return(RIGHT_SHIFT_LOGIC);			}
	"&"										{	return(BIT_AND);					}
	"and"									{	return(BIT_AND);					}
	"^"										{	return(BIT_XOR);					}
	"xor"									{	return(BIT_XOR);					}
	"|"										{	return(BIT_OR);						}
	"or"									{	return(BIT_OR);						}
	"<"										{	return(GRATER_THAN_LEFT);			}
	">"										{	return(GRATER_THAN_RIGHT);			}
	"<="									{	return(EQUAL_GRATER_THAN_LEFT);		}
	">="									{	return(EQUAL_GRATER_THAN_RIGHT);	}
	"="										{	return(EQUAL);						}
	"=="									{	return(EQUAL_EQUAL);				}
	"<>"									{	return(NOT_EQUAL);					}
	"!="									{	return(NOT_EQUAL);					}
	"&&"									{	return(LOGICAL_AND);				}
	"||"									{	return(LOGICAL_OR);					}
	","										{	return(COMMA);						}
	"["										{	return(LEFT_INDEX_BRACKET);			}
	"]"										{	return(RIGHT_INDEX_BRACKET);		}
	"-"{NUMBER} 							{
												printf("NUMBER=%s\n", yytext);
												SET_YYLVAL(yytext); return(MINUS_INT_RETERAL);
											}
	{NUMBER} 								{
												printf("NUMBER=%s\n", yytext);
												SET_YYLVAL(yytext); return(INT_RETERAL);
											}



%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* 予約語のコール
	*	責務：RESERVED_WORD を検出する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
"bplusrecv" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"bplussend" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"callmenu" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"changedir" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"clearscreen" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"closett" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"connect" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"cygconnect" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"disconnect" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"dispstr" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"enablekeyb" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"flushrecv" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"gethostname" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getmodemstatus" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"gettitle" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"kmtfinish" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"kmtget" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"kmtrecv" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"kmtsend" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"loadkeymap" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"logautoclosemode" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"logclose" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"loginfo" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"logopen" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"logpause" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"logrotate" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"logstart" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"logwrite" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"quickvanrecv" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"quickvansend" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"recvln" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"restoresetup" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"scprecv" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"scpsend" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"send" 				{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sendbreak" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sendbroadcast" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sendfile" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sendkcode" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sendln" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sendlnbroadcast" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sendlnmulticast" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sendmulticast" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setbaud"	 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setdebug" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setdtr" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setecho" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setflowctrl" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setmulticastname" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setrts" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setspeed" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setsync" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"settitle" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"showtt" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"testlink" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"unlink" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"wait" 				{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"wait4all" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"waitevent" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"waitln" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"waitn" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"waitrecv" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"waitregex" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"xmodemrecv" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"xmodemsend" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"ymodemrecv" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"ymodemsend" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"zmodemrecv" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"zmodemsend" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"end" 				{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"execcmnd" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"exit" 				{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"mpause" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"pause" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"return" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"code2str" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"expandenv" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"int2str" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"regexoption" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sprintf" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"sprintf2" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"str2code" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"str2int" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strcompare" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strconcat" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strcopy" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strinsert" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strjoin" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strlen" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strmatch" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strremove" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strreplace" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strscan" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strspecial" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strsplit" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strtrim" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"tolower" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"toupper" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"basename" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"dirname" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"fileclose" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"fileconcat" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filecopy" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filecreate" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filedelete" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filelock" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filemarkptr" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"fileopen" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filereadln" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"fileread" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filerename" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filesearch" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"fileseek" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"fileseekback" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filestat" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filestrseek" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filestrseek2" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filetruncate" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"fileunlock" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filewrite" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filewriteln" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"findfirst"			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"findnext"			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"findclose" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"foldercreate" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"folderdelete" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"foldersearch" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getdir" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getfileattr" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"makepath" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setdir" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setfileattr" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"delpassword" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getpassword" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"ispassword" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"passwordbox" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setpassword" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"beep" 				{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"bringupbox" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"checksum8" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"checksum8file" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"checksum16" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"checksum16file" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"checksum32" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"checksum32file" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"closesbox" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"clipb2var" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"crc16" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"crc16file" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"crc32" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"crc32file" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"exec" 				{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"dirnamebox" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"filenamebox" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getdate" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getenv" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getipv4addr" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getipv6addr" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getspecialfolder" 	{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"gettime" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getttdir" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"getver" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"ifdefined" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"inputbox" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"intdim" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"listbox" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"messagebox" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"random" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"rotateleft" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"rotateright" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setdate" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setdlgpos" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setenv" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"setexitcode" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"settime" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"show" 				{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"statusbox" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"strdim" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"uptime" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"var2clipb" 		{ SET_YYLVAL(yytext); return(RESERVED_WORD); }
"yesnobox" 			{ SET_YYLVAL(yytext); return(RESERVED_WORD); }

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* コメントの検出処理
	*	責務：コメント内容を無視し、BEGIN(INITIAL) する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
	"/*"            						{	BEGIN(ST_COMMENT); yymore();	}
	<ST_COMMENT>"*/"   						{	BEGIN(INITIAL);					}
	<ST_COMMENT>"*"    						{	yymore(); 						}
	<ST_COMMENT>[^*]+  						{	yymore(); 						}
	"//".*(\r|\n) 							{									}
	"//"									{									}

%{  /*********************************************************************************
	*  import を検出する。
	*/ %}
	import									{	return(IMPORT);						}

%{  /*********************************************************************************
	*  extern を検出する。
	*/ %}
	extern									{	return(EXTERN);						}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* 文字列リテラルの検出処理
	*	責務：文字列リテラルを検出し、SET_YYLVALし、BEGIN(INITIAL)し、return(STR_RETERAL)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
	"\""            						{	BEGIN(ST_STR_RETERAL); yymore();						}
	<ST_STR_RETERAL>"\""   					{	BEGIN(INITIAL); SET_YYLVAL(yytext); return(STR_RETERAL);	}
	<ST_STR_RETERAL>.	  					{	yymore(); 												}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* ファイル終端処理。ここが終わり。 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
<<EOF>>			{ // printf("end of file\n");
					return(0); }

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* トークンの検出処理
	*	責務：トークンを検出し、SET_YYLVALし、return(TOKEN)する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
	{letter}								{ SET_YYLVAL(yytext); return(TOKEN); }
%%

#define C_OUTPUT_FILE_MAX    (256)

void yyerror(char const*){
}
/*****************************************************************************************************************************************************************
	エントリーポイント
******************************************************************************************************************************************************************/
int main(int argc, char *argv[])
{
    FILE * fptr_r = NULL;
    FILE * fptr_w = NULL;
    int i;
    char opt;
    char output_filne_name[C_OUTPUT_FILE_MAX] = {0};
    char input_filne_name[C_OUTPUT_FILE_MAX] = {0};

#ifdef DEBUGOUT
	yydebug = YYDEBUG;
#endif

    /* default name. */
    strncpy(output_filne_name, "out.ttl", C_OUTPUT_FILE_MAX);

    for(i = 1; i < argc; ++i){
        if(*argv[i] == '-'){
            opt = *(argv[i]+1);
            switch(opt){
                case 'o':
                    strncpy(output_filne_name, argv[i+1], C_OUTPUT_FILE_MAX);
                    break;
                default:
                    printf("Undefined Option.\n");
                    break;
            }
            i++;
        } else {
            sprintf(input_filne_name, "%s", argv[i]);
        }
    }
    /* input filename error check */
    if(strlen(input_filne_name) == 0) {
        printf("input filename error.\n");
        exit(1);
    }
    /* Read file pointer */
    if ((fptr_r = fopen(input_filne_name, "r"))==NULL) {
        printf("file open failed.\n");
        exit(1);
    }
    
    /* write file pointer */
    if ((fptr_w = fopen(output_filne_name, "w"))==NULL) {
        printf("output file open failed.\n");
        exit(1);
    }

    /* 構文解析関数 yyparse */
    yyin = fptr_r;
    output_file_ptr = fptr_w;
    if( yyparse() != 0 ){
        printf("parse error.\n");
    }
    fclose(fptr_r);
    fclose(fptr_w);
    return 0;
}
