#include "credential_protection.h"

#include <windows.h>
#include <wincrypt.h>
#include <wtsapi32.h>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <limits>
#include <vector>

namespace {
using Bytes = std::vector<uint8_t>;
using Value = flutter::EncodableValue;

bool SessionUnlocked() {
  LPWSTR info = nullptr;
  DWORD size = 0;
  if (!WTSQuerySessionInformationW(WTS_CURRENT_SERVER_HANDLE,
                                   WTS_CURRENT_SESSION, WTSSessionInfoEx,
                                   &info, &size)) {
    return false;
  }
  const auto* session = reinterpret_cast<const WTSINFOEXW*>(info);
  const bool unlocked = size >= sizeof(WTSINFOEXW) && session->Level == 1 &&
      session->Data.WTSInfoExLevel1.SessionFlags == WTS_SESSIONSTATE_UNLOCK;
  WTSFreeMemory(info);
  return unlocked;
}

const Bytes* Argument(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(Value(key));
  if (it == args.end()) return nullptr;
  return std::get_if<Bytes>(&it->second);
}

bool MakeBlob(const Bytes* bytes, DATA_BLOB* blob) {
  if (!bytes || bytes->empty() ||
      bytes->size() > std::numeric_limits<DWORD>::max()) return false;
  blob->cbData = static_cast<DWORD>(bytes->size());
  blob->pbData = const_cast<BYTE*>(bytes->data());
  return true;
}
}  // namespace

void RegisterCredentialProtection(flutter::BinaryMessenger* messenger) {
  flutter::MethodChannel<Value> channel(messenger,
      "app.dourstuff/credential-record/v1",
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler([](const auto& call, auto result) {
    const bool seal = call.method_name() == "seal";
    if (!seal && call.method_name() != "open") {
      result->NotImplemented();
      return;
    }
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    DATA_BLOB input{}, entropy{}, output{};
    if (!args || !MakeBlob(Argument(*args, "context"), &entropy) ||
        !MakeBlob(Argument(*args, "data"), &input) || !SessionUnlocked()) {
      result->Error("unavailable");
      return;
    }
    // Current user only. The journal's complete record context is entropy.
    BOOL ok = seal
        ? CryptProtectData(&input, nullptr, &entropy, nullptr, nullptr,
                           CRYPTPROTECT_UI_FORBIDDEN, &output)
        : CryptUnprotectData(&input, nullptr, &entropy, nullptr, nullptr,
                             CRYPTPROTECT_UI_FORBIDDEN, &output);
    if (ok && SessionUnlocked()) {
      result->Success(Value(Bytes(output.pbData, output.pbData + output.cbData)));
    } else {
      result->Error("unavailable");
    }
    if (output.pbData) {
      SecureZeroMemory(output.pbData, output.cbData);
      LocalFree(output.pbData);
    }
  });
}
