#!/usr/bin/env bash

# 在包含 .env 文件的项目目录中，
# 通过环境变量设置 migrate 的迁移定义格式（*.sql）、所在目录以及数据库连接信息

if ! command -v migrate > /dev/null 2>&1; then
    echo "未安装 golang-migrate"
    echo "下载地址：https://github.com/golang-migrate/migrate/releases"
    exit 1
fi

if [ ! -f .env ]; then
    echo "当前目录下没有找到 .env 文件"
    exit 1
fi

PROJECT_DIR="$(pwd)"
export $(cat "$PROJECT_DIR/.env" | egrep -v "(^#.*|^$)" | xargs)

if [ -z "$MIGRATE_DATABASE" ]; then
    echo "未定义环境变量 \$MIGRATE_DATABASE"
    exit 1
else
    echo "目标数据库：$(echo "$MIGRATE_DATABASE" | sed 's/:\([^:]*\)@/:****@/')"
fi

MIGRATIONS_DIR="$(readlink -f "${MIGRATION_SOURCE:-migrations}")"
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "$MIGRATIONS_DIR 目录不存在"
    exit 1
else
    echo "迁移定义所在目录：$MIGRATIONS_DIR"
fi

if [ "$#" -eq 0 ]; then
    echo "请指定操作类型，可选：create、up、down、force、version"
    exit 1
fi

set -eu

if [ "$1" = "create" ]; then
    if [ "$#" -lt 2 ]; then
        echo "请指定 migration 名称"
        exit 1
    fi

    migrate create -ext sql -dir "$MIGRATIONS_DIR" -seq "$2"
elif [ "$1" = "up" ] || [ "$1" = "down" ] || [ "$1" = "force" ] || [ "$1" = "version" ]; then
    migrate -database "$MIGRATE_DATABASE" -path "$MIGRATIONS_DIR" "$@"
else
    echo "操作类型无效，可选：create、up、down、force"
    exit 1
fi
