#!/bin/bash
# helpを作成
function usage {
  cat <<EOM
Usage: $(basename "$0") <target_file> [OPTION]
  -h          Display help
  -o VALUE    出力ファイル名(省略時は out.ttl として生成される)
EOM
  exit 2
}

# optionをパース
OPTION_STR=

# 引数別の処理定義
while (( $# > 0 ))
do
    case $1 in
    -o)
        OPTION_STR="-o "$2
        shift
        ;;
    -h)
        usage
        exit 1
        ;;
    *)
        TARGET_FILE=$1
    ;;
    esac
    shift
done

# コンパイル実行
./ttlcpp ${TARGET_FILE}
./ttlcc out.ttlcs ${OPTION_STR}
rm ./out.ttlcs
