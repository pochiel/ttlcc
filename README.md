# ttlcc
 A wrapper language transpiler that outputs Tera Term macros.
 Tera Term マクロを出力するラッパー言語のトランスパイラ。

# ttlcとは
ttlc(Tera Term Language custom)とは、Tera Termのマクロ言語である
ttl(Tera Term Language)のラッパー言語である。
ttlc ソースコードをトランスパイルし、ttl マクロを生成することを目標とする。
ttlc は下記の特徴を持つ。

* 再入可能な関数
* ローカルスコープとローカル変数
* 直感的に理解しやすい include
* 演算子による文字列処理、型キャスト

# 関数と予約語
ttlcは再入可能な関数に対応している。
main関数は ttlc の Entory Point である。
下記は ttlc における Hello, world である。

```
	func int main()
		/* first program */
		sendln('Hello, world');
		return 0;
	endfunc
```

関数は func ～ endfunc で囲まれたスコープで定義され、複数の引数と複数の戻り値を持つことができる。
戻り値に指定することができる型は int string void の3種である。　変数の型については後述する。
コメントは ```/* */``` であらわされる範囲コメントと、```//``` であらわされる 1行コメントが存在する。
行末は ; によって閉じている必要がある。
C の表記に倣い、return はカッコを付けなくてもよい。
ttl における命令は基本的には予約語となり、ttlcにおいても同様に使用できるが、呼び出し表記は ttlc の関数呼び出しの表記と同様に書かれなければならない。
ただし、下記命令の使用方法は ttl のそれと異なる。

* return：サブルーチンリターンだけでなく、複数の戻り値を戻すことができる。
* goto：使用できない。(予定 Ver0.0現在）
* gosub：使用できない。(予定 Ver0.0現在）

上述したとおり、main関数は ttlc マクロプログラムの Entry Point であるが、ライブラリを作成したい場合 main関数は省略しなければならない。
ライブラリ用途の ttlc プログラムは、エラーチェックのためにトランスパイルすることはできるが、ttl マクロの実体を生成しない。
あくまで、main関数を持つプログラム本体から import されて使用されることを想定する。
（※この仕様は将来バージョンで変更される可能性がある）

上述の通り、ttlc における関数は戻り値も複数持つことができる。
下記は、int型を4つreturnする関数である。

```
	func int int int int get_address_offset(string ip_addr)
		string ret[4];
		ret = split(ip_addr, ".");		// IPV4 アドレスを . で分解する。
		return ret[0], ret[1], ret[2], ret[3];
	endfunc
```

関数で return する際、戻り値の数が足りないとトランスパイル時エラーとなる。
また、関数呼び出し側は下記のように使用するが、これまた受け側の変数が足りないとトランスパイル時エラーとなる。

```
int ip_addr[4];
ip_addr[0], ip_addr[1], ip_addr[2], ip_addr[3] = get_address_offset("192.168.123.111");

```


# importについて
ttl には include 命令が存在するが、その実態は別プログラムへの制御乗り換え命令であり
C における include のような挙動を想定していると、痛い目を見ることになる。
また、この特殊な仕様が災いして、共通処理をライブラリにまとめ、それをメインプログラムから読み込んで使う。　というごく一般的な使い方がとてもやりづらい。

ttlc ではより直感的に外部プログラムを取り込むための命令として import 命令を実装している。
これを使用することで、共通処理をライブラリ化し、メインプログラムから呼び出して使うことができる。

# 変数と型とスコープ
ttlc では、変数を宣言することができ、それは下記のような型持つ。

```
int	n;						               /* 整数型変数n （未初期化の場合、0で初期化される） */
string name;				           /* 文字列型変数name （未初期化の場合、空文字列で初期化される） */
int j=100;					            /* 整数型変数j （100で初期化される） */
string name = "Tera Term";	/* 文字列型変数name （Tera Term）で初期化される。 */
```
ttlc の変数は下記のスコープを持つ

* ローカルスコープ  ：関数内部で宣言される。関数外からは参照できない。
* グローバルスコープ：関数外部で宣言される。関数内外から参照できる。

ttlc は通常の変数の他に、配列と参照をを持つ。

* [int/string] name&    参照変数name
* [int/string] name[n]	 要素数nの配列name

多次元配列、クラス、構造体、共用体は言語仕様としてサポートしない。(予定 Ver 0.0現在）
ttlc はVer 0.0にて定数定義をサポートしない。将来版でサポートするかどうかは不明であるが、可能ならばサポートしたい。

ttlc は型キャストが可能である。

## 整数型→文字列型
下記のように明示的に型キャストすることで、変換することができる。

```
int num=100;
string num_str;
num_str = (string)num; // num_str は "100"
```

また、整数型→文字列型の変換は + 演算子、もしくは =演算子を使用することで暗黙に行われる。

```
 // +演算子による暗黙の型キャスト
	int ip_addr_num = 111;
	string subnet = "192.168.123";
	string ip_addr = "";
	ip_addr = subnet + "." + ip_addr_num;	// 192.168.123.111
```

```
 // =演算子による暗黙の型キャスト
	int ip_addr_num = 111;
 string ip_addr_num_str = ip_addr_num;
	string subnet = "192.168.123";
	string ip_addr = "";
	ip_addr = subnet + "." + ip_addr_num;	// 192.168.123.111
```

## 文字列型→整数型
下記のように明示的に型キャストすることで、変換することができる。

```
string num_str="100";
int num=10;
num = num + (int)num_str; // num は "110"
```

この時、キャスト対象の変数やリテラルが数値変換不可能な値だった場合、トランスパイルエラー、もしくは実行時エラーとなってマクロの挙動が停止する。

```
string num_str="100ab";
int num=10;
num = num + (int)num_str; // num は "110"
```

また、文字列型→整数型の暗黙の型キャストは行われない。

# 16進数の扱い
ttlc では定義時に 0x を付けることで、16進数を扱うことができる。
下記はそれぞれの型における 16 進数での表記である。

```
int num=0xFF;
string num_str="0xFF";  // 整数型にキャストすると 0xFF(255)になる
```

# 演算子と優先順位
T.B.D. 


# 制御構文

## if文
```
	if (x==0) then
		// process...
	elseif (x==1) then
		// process...
	else
		// process...
	endif
```
```
	int ip_addr_num = 111;
	string subnet = "192.168.123";
	string ip_addr = "";
	if ( (subnet + "." + (string)ip_addr_num) == "192.168.123.111" ) then
		/* do anything */
	endif
```

## while文

```
	while i>0
		i = i - 1
	endwhile
```

## do while~loop文

```
	do while i > 0
		i = i - 1
	loop
```

## for文

```
	for i=1 to 10
		// any process
	next
```

```
	for i=1 to 10 step 2
		// any process
	next
```

## break, continue

```
	for i=1 to 100
		if ((i%3)==0)&&((i%5)==0) then
			// FizBuz!
			// ?????I??
			sendln('FizzBuzz');
			break;
		elseif ((i%5)==0)
			sendln('buzz');
		elseif ((i%3)==0)
			sendln('Fizz');
		else
			continue;
		endif
	next
```
