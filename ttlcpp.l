%{
#include "t_token.hpp"
#include "pp_parser.hpp"
#include <string.h>
#include <string>
#include <regex>

extern FILE * output_file_ptr;
extern "C" int yylex();
extern int yyparse();
#ifdef DEBUGOUT
extern int yydebug;
extern void yyerror(char const*);
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
%x ST_DEFINE_NAME
%x ST_DEFINE_VAL
%x ST_STR_RETERAL

%%

[ ]												{	yymore();	}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* define を検出して通知する
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
	^#define								 	{
													BEGIN(ST_DEFINE_NAME);
													return (DEFINE);
												}
	<ST_DEFINE_NAME>{letter}							{
													printf("DEFINE=%s\n", yytext);
													SET_YYLVAL(yytext);
													BEGIN(ST_DEFINE_VAL);
													return(TOKEN);
												}
	<ST_DEFINE_NAME>[ |\t]+						{ }
	<ST_DEFINE_VAL>.							{	yymore();	}
	<ST_DEFINE_VAL>[\r|\n]						{
													printf("DEFINE VAL=%s\n", yytext);
													SET_YYLVAL(yytext);
													BEGIN(INITIAL); 
													return(DEFINE_VAL);
												}

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
	^#import								{	return(IMPORT);						}


%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* ファイル終端・もしくは改行　バッファの内容を吐き出して、次の行に備えるか、プログラムを終える。 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
[\r|\n]			{
					SET_YYLVAL(yytext);
					return (OTHER_CODE);
				}
<<EOF>>			{
					return 0;
				}

%{  /*****************************************************************************************************************************************************************
	******************************************************************************************************************************************************************
	* その他のコードの検出処理
	*	責務：上記に引っかからなかったコードを yymore する 
	******************************************************************************************************************************************************************
	******************************************************************************************************************************************************************/ %}
.				{ yymore(); }
%%

#define C_OUTPUT_FILE_MAX    (256)

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
    strncpy(output_filne_name, "out.ttlcs", C_OUTPUT_FILE_MAX);

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
	/* パース開始 */
    if( yyparse() != 0 ){
        printf("parse error.\n");
    }
    fclose(fptr_r);
    fclose(fptr_w);
    return 0;
}
