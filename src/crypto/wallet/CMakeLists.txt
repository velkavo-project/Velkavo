# Copyright (c) 2020-2024, Velkavo

#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of
#    conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list
#    of conditions and the following disclaimer in the documentation and/or other
#    materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be
#    used to endorse or promote products derived from this software without specific
#    prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
# Ensure supercop crypto functions are available when this file is processed
# independently (e.g. IDE or subdirectory builds that bypass the root CMakeLists).
#
if (NOT COMMAND velkavo_crypto_autodetect)
  include(${CMAKE_SOURCE_DIR}/external/supercop/functions.cmake)
endif()

#
# Possibly user defined values.
#
set(VELKAVO_WALLET_CRYPTO_LIBRARY "auto" CACHE STRING "Select a wallet crypto library")

#
# If the user specified "auto", detect best library defaulting to internal.
#
if (${VELKAVO_WALLET_CRYPTO_LIBRARY} STREQUAL "auto")
   velkavo_crypto_autodetect(AVAILABLE BEST)
  if (DEFINED BEST)
    message("Wallet crypto is using ${BEST} backend")
    set(VELKAVO_WALLET_CRYPTO_LIBRARY ${BEST})
  else ()
    message("Defaulting to internal crypto library for wallet")
    set(VELKAVO_WALLET_CRYPTO_LIBRARY "cn")
  endif ()
endif ()

#
# Configure library target "wallet-crypto" - clients will use this as a
# library dependency which in turn will depend on the crypto library selected.
#
if (${VELKAVO_WALLET_CRYPTO_LIBRARY} STREQUAL "cn")
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/empty.h.in ${VELKAVO_GENERATED_HEADERS_DIR}/crypto/wallet/ops.h)
  add_library(wallet-crypto ALIAS cncrypto)
else ()
  velkavo_crypto_generate_header(${VELKAVO_WALLET_CRYPTO_LIBRARY} "${VELKAVO_GENERATED_HEADERS_DIR}/crypto/wallet/ops.h")
  velkavo_crypto_get_target(${VELKAVO_WALLET_CRYPTO_LIBRARY} CRYPTO_TARGET)
  add_library(wallet-crypto $<TARGET_OBJECTS:${CRYPTO_TARGET}>)
  target_link_libraries(wallet-crypto cncrypto)
endif ()


