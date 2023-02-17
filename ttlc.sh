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

OPTION_STR=

# 引数別の処理定義
while getopts ":o:h" optKey; do
  case "$optKey" in
    o)
        OPTION_STR="-n " ${OPTARG}
        ;;
    '-h'|'--help'|* )
      usage
      ;;
  esac
done
# コンパイル実効
./ttlcpp $1
./ttlcc out.ttlcs ${OPTION_STR}
rm ./out.ttlcs
