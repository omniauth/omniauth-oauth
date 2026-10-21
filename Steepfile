D = Steep::Diagnostic

target :lib do
  signature "sig", "steep/shims"
  check "lib"

  library "net-http", "openssl", "timeout"

  configure_code_diagnostics(D::Ruby.strict)
end
