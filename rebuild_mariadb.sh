#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="${repo_root}/build"

export ROCKSDB_LIB=$(pwd)/storage/rocksdb/rocksdb/librocksdb.a
export ROCKSDB_INC=$(pwd)/storage/rocksdb/rocksdb/include

if [[ -z "${ROCKSDB_LIB:-}" || -z "${ROCKSDB_INC:-}" ]]; then
  echo "ROCKSDB_LIB and ROCKSDB_INC environment variables must be set." >&2
  exit 1
fi

mkdir -p "${build_dir}"
cd "${build_dir}"

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_STANDARD_REQUIRED=ON -DCMAKE_CXX_EXTENSIONS=OFF \
  -DROCKSDB_EXTERNAL_LIB="${ROCKSDB_LIB}" \
  -DROCKSDB_EXTERNAL_INC="${ROCKSDB_INC}" \
  -DUPDATE_SUBMODULES=OFF \
  -DPLUGIN_ROCKSDB=DYNAMIC \
  -DWITH_WSREP=OFF

make -j"$(nproc)" > make.LOG 2>&1
tail -n 10 make.LOG

cd "${repo_root}"
