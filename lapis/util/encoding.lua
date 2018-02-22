local encode_base64, decode_base64, hmac_sha1
local config = require("lapis.config").get()
local openssl_hmac = require("openssl.hmac")
if ngx then
  do
    local _obj_0 = ngx
    encode_base64, decode_base64, hmac_sha1 = _obj_0.encode_base64, _obj_0.decode_base64, _obj_0.hmac_sha1
  end
else
  local mime = require("mime")
  local b64, unb64
  b64, unb64 = mime.b64, mime.unb64
  encode_base64 = function(...)
    return (b64(...))
  end
  decode_base64 = function(...)
    return (unb64(...))
  end
  hmac_sha1 = function(secret, str)
    local hmac = openssl_hmac.new(secret, "sha1")
    return hmac:final(str)
  end
end
local encode_with_secret
encode_with_secret = function(object, secret, sep)
  if secret == nil then
    secret = config.secret
  end
  if sep == nil then
    sep = "."
  end
  local json = require("cjson")
  local msg = encode_base64(json.encode(object))
  local signature = encode_base64(hmac_sha1(secret, msg))
  return msg .. sep .. signature
end
local decode_with_secret
decode_with_secret = function(msg_and_sig, secret)
  if secret == nil then
    secret = config.secret
  end
  local json = require("cjson")
  local msg, sig = msg_and_sig:match("^(.*)%.(.*)$")
  if not (msg) then
    return nil, "invalid format"
  end
  sig = decode_base64(sig)
  if not (sig == hmac_sha1(secret, msg)) then
    return nil, "invalid signature"
  end
  return json.decode(decode_base64(msg))
end
return {
  encode_base64 = encode_base64,
  decode_base64 = decode_base64,
  hmac_sha1 = hmac_sha1,
  encode_with_secret = encode_with_secret,
  decode_with_secret = decode_with_secret
}
