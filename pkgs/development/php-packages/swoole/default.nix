{
  lib,
  stdenv,
  buildPecl,
  php,
  valgrind,
  pcre2,
  fetchFromGitHub,
}:

let
  version = "6.0.1";
in
buildPecl {
  inherit version;
  pname = "swoole";

  src = fetchFromGitHub {
    owner = "swoole";
    repo = "swoole-src";
    rev = "v${version}";
    hash = "sha256-WeTl+/OVcXFl39qfYoYRk2MQ7PYKlbjHxddp/kFov6g=";
  };

  buildInputs = [ pcre2 ] ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [ valgrind ];

  # tests require internet access
  doCheck = false;

  meta = {
    changelog = "https://github.com/swoole/swoole-src/releases/tag/v${version}";
    description = "Coroutine-based concurrency library for PHP";
    homepage = "https://www.swoole.com";
    license = lib.licenses.asl20;
    maintainers = lib.teams.php.members;
  };
}
